// Integration test of the trends pipeline against a real database with the migrations applied
// (poll -> draft -> publish through pgStore). Skipped unless TRENDS_TEST_DB_URL is set to a local
// Postgres reachable over TCP, e.g. a cluster from supabase/tests/local/run_local.sh (KEEP_CLUSTER=1)
// restarted with listen_addresses=localhost, or `supabase start`:
//   TRENDS_TEST_DB_URL=postgres://postgres:postgres@127.0.0.1:54322/postgres \
//     deno test --allow-env --allow-net --allow-read --allow-write --allow-sys tests/trends_store_test.ts
// It deletes and recreates rows in the trends schema only: never point it at a real project.
import { assert, assertEquals } from "@std/assert";
import postgres from "postgres";
import { makeClaude } from "../_shared/trends/claude.ts";
import { runDraft } from "../_shared/trends/run_draft.ts";
import { runPoll } from "../_shared/trends/run_poll.ts";
import { runPublish, type TrendsStorage } from "../_shared/trends/run_publish.ts";
import { pgStore } from "../_shared/trends/store.ts";
import { claudeFetch } from "./trends_fixtures.ts";

const DB = Deno.env.get("TRENDS_TEST_DB_URL");

const TRENDS_XML = `<rss xmlns:ht="https://trends.google.com/trending/rss" version="2.0"><channel><item>
<title>testville first snow</title><ht:approx_traffic>50,000+</ht:approx_traffic>
<ht:news_item><ht:news_item_title>First snow expected in the city by the weekend</ht:news_item_title>
<ht:news_item_snippet>Forecasters expect several inches of snow in the city by the weekend.</ht:news_item_snippet>
<ht:news_item_url>https://forecast.example.com/testville-snow</ht:news_item_url><ht:news_item_source>Example Forecast</ht:news_item_source></ht:news_item>
<ht:news_item><ht:news_item_title>Hardware stores see a rush on snow blowers</ht:news_item_title>
<ht:news_item_snippet>Hardware stores reported more interest in snow blowers this week.</ht:news_item_snippet>
<ht:news_item_url>https://metro.example.net/testville-stores</ht:news_item_url><ht:news_item_source>Example Metro</ht:news_item_source></ht:news_item>
<ht:news_item><ht:news_item_title>Testville snow: first snow brings plows out</ht:news_item_title>
<ht:news_item_url>https://third.example.org/plows</ht:news_item_url><ht:news_item_source>Third</ht:news_item_source></ht:news_item>
</item></channel></rss>`;

class MemStorage implements TrendsStorage {
  files = new Map<string, string>();
  put(p: string, b: string) {
    this.files.set(p, b);
    return Promise.resolve();
  }
  remove(p: string) {
    this.files.delete(p);
    return Promise.resolve();
  }
  get(p: string) {
    return Promise.resolve(this.files.get(p) ?? null);
  }
}

Deno.test({
  name: "pgStore: poll -> draft -> publish end to end on the migrated schema",
  ignore: !DB,
  sanitizeResources: false,
  sanitizeOps: false,
  async fn() {
    const sql = postgres(DB!, { onnotice: () => {} });
    try {
      await sql`delete from trends.trend_drafts`;
      await sql`delete from trends.trend_signals`;
      await sql`delete from trends.trend_topics`;
      await sql`delete from trends.trend_runs`;
      await sql`update trends.trend_sources set enabled = false`;
      await sql`delete from trends.trend_sources where place_slug = 'testville'`;
      await sql`insert into trends.trend_sources (kind, country, geo, place_slug, place_name, state, level)
                values ('google_trends', 'usa', 'US-IL', 'testville', 'Testville', 'Illinois', 'metro')`;
      await sql`update trends.trend_settings set value = jsonb_set(value, '{min_signals}', '3') where key = 'detection'`;
      await sql`update trends.trend_settings set value = '{"paused": false, "paused_at": null}' where key = 'publishing'`;

      const store = pgStore(DB!);
      const now = () => new Date();
      const feed = (() => Promise.resolve(new Response(TRENDS_XML))) as typeof fetch;
      const poll = await runPoll({ store, fetch: feed, reddit: null, now });
      assertEquals(poll.signals_new, 4);
      assertEquals(poll.topics_new, 1);
      assertEquals(poll.fired.length, 1, JSON.stringify(poll));
      const [t] = await sql`select status, domain_count, signal_count from trends.trend_topics where place_slug = 'testville'`;
      assertEquals([t.status, t.domain_count, t.signal_count], ["fired", 3, 4]);

      // re-polling the same feed adds nothing and keeps one topic
      const again = await runPoll({ store, fetch: feed, reddit: null, now });
      assertEquals([again.signals_new, again.topics_new], [0, 0]);

      const cf = claudeFetch({});
      const draft = await runDraft({ store, claude: makeClaude({ apiKey: "k", model: "claude-sonnet-5-5", fetch: cf.fetch }), now });
      assertEquals(draft.queued, 1, JSON.stringify(draft));
      const [d] = await sql`select status, slug, gates, article is not null as has_article from trends.trend_drafts`;
      assertEquals([d.status, d.has_article], ["queued", true]);
      assert(d.gates.sources.passed && d.gates.balance.passed);

      const storage = new MemStorage();
      const pub = await runPublish({ store, storage, deployHook: null, fetch: feed, now });
      assertEquals(pub.published, [d.slug]);
      const index = JSON.parse(storage.files.get("index.json")!);
      assertEquals(index.articles[0].slug, d.slug);
      const [p] = await sql`select status, storage_path from trends.trend_drafts`;
      assertEquals([p.status, p.storage_path], ["published", `articles/${d.slug}.json`]);
      const logs = await sql`select decision from trends.trend_publish_log order by id`;
      assert(logs.some((l) => l.decision === "published"));
      const runs = await sql`select count(*)::int as n from trends.trend_runs`;
      assertEquals(runs[0].n, 0); // runs are recorded by handleRun, not by the run functions
      await store.close();
    } finally {
      await sql`update trends.trend_sources set enabled = true where place_slug <> 'testville'`;
      await sql.end();
    }
  },
});
