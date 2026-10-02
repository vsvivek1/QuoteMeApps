#!/usr/bin/env python3
"""Render the legal pack (legal/<country>/*.md) into app and website outputs.

Outputs (paths relative to the repo root):
  assets/legal/<country>/legal.json         bundled in the app (Settings > Legal, sign-up)
  web/content/legal/<country>/<slug>.md     consumed by the country website (/legal/<slug>)

What it does:
  * fills {{PLACEHOLDERS}} from legal/config.json (per country) plus each page's
    front matter (VERSION, LAST_UPDATED, TITLE, SLUG);
  * generates the category policy table and regulatory disclaimers in
    community-guidelines.md from legal/<country>/category_policy.json;
  * inserts a "Version X · Last updated Y" line under each page's H1;
  * strips HTML comments (internal notes never reach users);
  * fails on unknown placeholders (typos) and, with --strict, on placeholders
    whose config value is still a {{PLACEHOLDER}} (i.e. not filled in yet).

Usage:
  python3 legal/build.py                 # build both countries, warn on pending values
  python3 legal/build.py --strict        # release builds: fail while anything is pending
  python3 legal/build.py --check         # validate only, write nothing
  python3 legal/build.py --country india

Standard library only (Python 3.9+).
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

LEGAL_DIR = Path(__file__).resolve().parent
REPO_ROOT = LEGAL_DIR.parent
CONFIG_PATH = LEGAL_DIR / "config.json"

COUNTRIES = ("usa", "india")

# Display order in the app's Settings > Legal list. Every page listed here must exist.
PAGE_ORDER = {
    "usa": [
        "terms-of-service", "privacy-policy", "ccpa-notice", "coppa", "community-guidelines",
        "seller-terms", "subscription-terms", "refund-cancellation", "account-deletion",
        "cookie-policy", "eula", "contact-support",
    ],
    "india": [
        "terms-of-service", "privacy-policy", "dpdp-consent-notice", "grievance-officer",
        "community-guidelines", "seller-terms", "subscription-terms", "refund-cancellation",
        "account-deletion", "cookie-policy", "eula", "contact-support",
    ],
}

REQUIRED_FRONT_MATTER = ("title", "slug", "version", "last_updated")
PLACEHOLDER_RE = re.compile(r"\{\{\s*([A-Z0-9_]+)\s*\}\}")
COMMENT_RE = re.compile(r"<!--(?!\s*CATEGORY_)(.*?)-->", re.S)
POLICY_LABEL = {"allowed": "Allowed", "restricted": "Restricted (licensed sellers only)", "blocked": "Blocked"}
POLICY_LABEL_INDIA = {"restricted": "Restricted (registered sellers only)"}


class BuildError(Exception):
    pass


def parse_front_matter(text: str, path: Path) -> tuple[dict, str]:
    if not text.startswith("---\n"):
        raise BuildError(f"{path}: missing YAML front matter")
    end = text.find("\n---\n", 4)
    if end == -1:
        raise BuildError(f"{path}: unterminated front matter")
    meta = {}
    for line in text[4:end].splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        key, sep, value = line.partition(":")
        if not sep:
            raise BuildError(f"{path}: bad front matter line {line!r}")
        meta[key.strip()] = value.strip().strip('"').strip("'")
    missing = [k for k in REQUIRED_FRONT_MATTER if not meta.get(k)]
    if missing:
        raise BuildError(f"{path}: front matter missing {', '.join(missing)}")
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", meta["last_updated"]):
        raise BuildError(f"{path}: last_updated must be YYYY-MM-DD")
    if meta["slug"] != path.stem:
        raise BuildError(f"{path}: slug {meta['slug']!r} must match the file name")
    return meta, text[end + 5:].lstrip("\n")


def md_cell(value: str) -> str:
    return (value or "-").replace("|", "\\|").replace("\n", " ")


def category_tables(country: str) -> tuple[str, str]:
    path = LEGAL_DIR / country / "category_policy.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    labels = dict(POLICY_LABEL)
    if country == "india":
        labels.update(POLICY_LABEL_INDIA)
    rows = ["| Category | Policy | At launch | Who may quote / licence rule |", "|---|---|---|---|"]
    disclaimers = []
    for cat in data["categories"]:
        policy, launch = cat["policy"], cat["launch_state"]
        if policy not in labels or launch not in labels:
            raise BuildError(f"{path}: unknown policy state in {cat['category']!r}")
        launch_text = "Same" if launch == policy else f"**{labels[launch]}** until legal sign-off"
        rows.append(
            f"| {md_cell(cat['category'])} | {labels[policy]} | {launch_text} | {md_cell(cat['licence'])} |"
        )
        if cat.get("disclaimer"):
            disclaimers.append(f"- **{cat['category']}:** {cat['disclaimer']}")
    return "\n".join(rows), "\n".join(disclaimers) or "- None."


def render(text: str, context: dict, path: Path, pending: set) -> str:
    def sub(match: re.Match) -> str:
        key = match.group(1)
        if key not in context:
            raise BuildError(f"{path}: unknown placeholder {{{{{key}}}}} (add it to legal/config.json)")
        value = str(context[key])
        for inner in PLACEHOLDER_RE.findall(value):
            pending.add(inner)
        return value

    return PLACEHOLDER_RE.sub(sub, text)


def add_version_line(body: str, meta: dict) -> str:
    line = f"_Version {meta['version']} · Last updated {meta['last_updated']}_"
    lines = body.splitlines()
    for i, current in enumerate(lines):
        if current.startswith("# "):
            return "\n".join(lines[: i + 1] + ["", line] + lines[i + 1:]) + "\n"
    return f"{line}\n\n{body}"


def build_country(country: str, config: dict, write: bool) -> tuple[int, set]:
    src_dir = LEGAL_DIR / country
    base_ctx = {k: v for k, v in config[country].items() if not k.startswith("_")}
    pending: set = set()
    pages = {}
    for path in sorted(src_dir.glob("*.md")):
        meta, body = parse_front_matter(path.read_text(encoding="utf-8"), path)
        if "<!-- CATEGORY_POLICY_TABLE -->" in body:
            table, disclaimers = category_tables(country)
            body = body.replace("<!-- CATEGORY_POLICY_TABLE -->", table)
            body = body.replace("<!-- CATEGORY_DISCLAIMERS -->", disclaimers)
        body = COMMENT_RE.sub("", body)
        body = re.sub(r"\n{3,}", "\n\n", body).strip() + "\n"
        body = add_version_line(body, meta)
        ctx = dict(base_ctx, VERSION=meta["version"], LAST_UPDATED=meta["last_updated"],
                   TITLE=meta["title"], SLUG=meta["slug"])
        rendered = render(body, ctx, path, pending)
        pages[meta["slug"]] = (meta, rendered)

    expected = PAGE_ORDER[country]
    missing = [s for s in expected if s not in pages]
    extra = [s for s in pages if s not in expected]
    if missing:
        raise BuildError(f"{country}: missing pages {missing}")
    if extra:
        raise BuildError(f"{country}: pages not in PAGE_ORDER {extra} (add them to build.py)")

    bundle = [
        {"slug": s, "title": pages[s][0]["title"], "version": pages[s][0]["version"],
         "last_updated": pages[s][0]["last_updated"], "markdown": pages[s][1]}
        for s in expected
    ]

    if write:
        app_out = REPO_ROOT / "assets" / "legal" / country / "legal.json"
        app_out.parent.mkdir(parents=True, exist_ok=True)
        app_out.write_text(json.dumps(bundle, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

        web_dir = REPO_ROOT / "web" / "content" / "legal" / country
        web_dir.mkdir(parents=True, exist_ok=True)
        for stale in web_dir.glob("*.md"):
            if stale.stem not in pages:
                stale.unlink()
        domain = render("{{WEB_DOMAIN}}", base_ctx, src_dir, set())
        for order, slug in enumerate(expected):
            meta, rendered = pages[slug]
            front = [
                "---",
                f"title: {json.dumps(meta['title'], ensure_ascii=False)}",
                f"slug: {slug}",
                f"version: {json.dumps(meta['version'])}",
                f"last_updated: {meta['last_updated']}",
                f"country: {country}",
                f"app_name: {json.dumps(base_ctx['APP_NAME'], ensure_ascii=False)}",
                f"company: {json.dumps(base_ctx['COMPANY_NAME'], ensure_ascii=False)}",
                f"canonical: {json.dumps(f'https://{domain}/legal/{slug}')}",
                f"order: {order}",
                "generated: true  # do not edit; source is legal/" + f"{country}/{slug}.md",
                "---",
                "",
            ]
            (web_dir / f"{slug}.md").write_text("\n".join(front) + rendered, encoding="utf-8")
    return len(bundle), pending


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--country", choices=COUNTRIES, action="append")
    parser.add_argument("--strict", action="store_true", help="fail while any placeholder is still pending")
    parser.add_argument("--check", action="store_true", help="validate only, do not write outputs")
    args = parser.parse_args()

    config = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    status = 0
    for country in args.country or COUNTRIES:
        try:
            count, pending = build_country(country, config, write=not args.check)
        except BuildError as exc:
            print(f"ERROR {exc}", file=sys.stderr)
            return 2
        verb = "checked" if args.check else "built"
        print(f"{country}: {verb} {count} pages")
        if pending:
            names = ", ".join("{{%s}}" % p for p in sorted(pending))
            level = "ERROR" if args.strict else "WARN"
            print(f"  {level} pending placeholders (fill in legal/config.json): {names}",
                  file=sys.stderr if args.strict else sys.stdout)
            if args.strict:
                status = 1
    return status


if __name__ == "__main__":
    sys.exit(main())
