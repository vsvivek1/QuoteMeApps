// Prebuild step: when TRENDS_DATA_URL is set, downloads the trends pipeline's public bucket into
// .trends-remote/ with the trends site's own script (web/trends_site/scripts/fetch-trends-data.mjs),
// for the "What's happening" section of town pages (src/lib/trends.ts). Unlike the trends site, a
// failed download does not fail this build: the section then uses committed articles only (or is
// hidden). Unset: nothing is downloaded.
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..');
const out = path.join(root, '.trends-remote');
if (!(process.env.TRENDS_DATA_URL ?? '').trim()) {
  fs.rmSync(out, { recursive: true, force: true });
  process.exit(0);
}
const script = path.resolve(root, '../trends_site/scripts/fetch-trends-data.mjs');
const r = spawnSync(process.execPath, [script], { cwd: root, stdio: 'inherit', env: process.env });
if (r.status !== 0) {
  fs.rmSync(out, { recursive: true, force: true });
  console.warn('[app_site] WARNING trends data could not be downloaded; town pages use committed trends articles only');
}
