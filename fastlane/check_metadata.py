#!/usr/bin/env python3
"""Check fastlane store metadata against Google Play and App Store limits.

  python3 fastlane/check_metadata.py                      # everything
  python3 fastlane/check_metadata.py --platform ios --country india

Runs automatically before every metadata upload (fastlane/lib/iwant_release.rb).
{{PLACEHOLDERS}} are counted as PLACEHOLDER_LEN characters (default 30, override with
the env var IWANT_PLACEHOLDER_LEN) because their real value is only known at upload time.
Exit code 1 on any violation. Standard library only.
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent / "metadata"
PLACEHOLDER = re.compile(r"\{\{\s*[A-Z0-9_]+\s*\}\}")
PLACEHOLDER_LEN = int(os.environ.get("IWANT_PLACEHOLDER_LEN", "30"))

LOCALES = {
    "android": {"usa": ["en-US", "es-US"], "india": ["en-IN", "hi-IN"]},
    "ios": {"usa": ["en-US", "es-MX"], "india": ["en-GB", "hi"]},
}

# file -> (max characters, required)
ANDROID_LIMITS = {
    "title.txt": 30,
    "short_description.txt": 80,
    "full_description.txt": 4000,
    "changelogs/default.txt": 500,
}
IOS_LIMITS = {
    "name.txt": 30,
    "subtitle.txt": 30,
    "keywords.txt": 100,  # checked in UTF-8 bytes as well (App Store Connect limit is 100 bytes)
    "description.txt": 4000,
    "promotional_text.txt": 170,
    "release_notes.txt": 4000,
    "privacy_url.txt": None,
    "support_url.txt": None,
    "marketing_url.txt": None,
}
IOS_ROOT_FILES = ["copyright.txt", "primary_category.txt", "secondary_category.txt"]
REVIEW_FILES = ["first_name.txt", "last_name.txt", "phone_number.txt", "email_address.txt",
                "demo_user.txt", "demo_password.txt", "notes.txt"]
OTHER_STORE = {"android": re.compile(r"\b(iPhone|iPad|App Store|Apple Watch)\b"),
               "ios": re.compile(r"\b(Android|Google Play|Play Store)\b")}


def effective_len(text: str) -> int:
    return len(PLACEHOLDER.sub("x" * PLACEHOLDER_LEN, text))


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8").strip()


def check_android(country: str, errors: list, report: list) -> None:
    base = ROOT / "android" / country
    present = sorted(p.name for p in base.iterdir() if p.is_dir()) if base.is_dir() else []
    if present != sorted(LOCALES["android"][country]):
        errors.append(f"android/{country}: locales {present}, expected {LOCALES['android'][country]}")
    for locale in LOCALES["android"][country]:
        for name, limit in ANDROID_LIMITS.items():
            path = base / locale / name
            if not path.exists():
                errors.append(f"{path.relative_to(ROOT)}: missing")
                continue
            text = read(path)
            n = effective_len(text)
            report.append((f"android/{country}/{locale}/{name}", n, limit))
            if not text:
                errors.append(f"{path.relative_to(ROOT)}: empty")
            if n > limit:
                errors.append(f"{path.relative_to(ROOT)}: {n} chars > {limit}")
            if OTHER_STORE["android"].search(text):
                errors.append(f"{path.relative_to(ROOT)}: mentions another store/platform")


def check_ios(country: str, errors: list, report: list) -> None:
    base = ROOT / "ios" / country
    present = sorted(p.name for p in base.iterdir() if p.is_dir() and p.name != "review_information") if base.is_dir() else []
    if present != sorted(LOCALES["ios"][country]):
        errors.append(f"ios/{country}: locales {present}, expected {LOCALES['ios'][country]}")
    for name in IOS_ROOT_FILES:
        if not (base / name).exists():
            errors.append(f"ios/{country}/{name}: missing")
    for name in REVIEW_FILES:
        if not (base / "review_information" / name).exists():
            errors.append(f"ios/{country}/review_information/{name}: missing")
    for locale in LOCALES["ios"][country]:
        name_words: set = set()
        name_path = base / locale / "name.txt"
        if name_path.exists():
            name_words = {w.lower() for w in re.findall(r"\w+", read(name_path))}
        for name, limit in IOS_LIMITS.items():
            path = base / locale / name
            rel = path.relative_to(ROOT)
            if not path.exists():
                errors.append(f"{rel}: missing")
                continue
            text = read(path)
            if not text:
                errors.append(f"{rel}: empty")
                continue
            if name.endswith("_url.txt"):
                if not text.startswith("https://") or "\n" in text:
                    errors.append(f"{rel}: must be a single https:// URL")
                continue
            n = effective_len(text)
            report.append((f"ios/{country}/{locale}/{name}", n, limit))
            if n > limit:
                errors.append(f"{rel}: {n} chars > {limit}")
            if OTHER_STORE["ios"].search(text):
                errors.append(f"{rel}: mentions another store/platform")
            if name == "name.txt" and n < 2:
                errors.append(f"{rel}: name must be at least 2 characters")
            if name == "keywords.txt":
                size = len(text.encode("utf-8"))
                report.append((f"ios/{country}/{locale}/keywords.txt (bytes)", size, 100))
                if size > 100:
                    errors.append(f"{rel}: {size} bytes > 100")
                if re.search(r"\s", text):
                    errors.append(f"{rel}: keywords must not contain spaces")
                items = text.split(",")
                if any(not k for k in items):
                    errors.append(f"{rel}: empty keyword (double or trailing comma)")
                lowered = [k.lower() for k in items]
                dupes = sorted({k for k in lowered if lowered.count(k) > 1})
                if dupes:
                    errors.append(f"{rel}: duplicate keywords {dupes}")
                in_name = sorted(set(lowered) & name_words)
                if in_name:
                    errors.append(f"{rel}: keywords repeat words from the app name {in_name}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--platform", choices=["android", "ios", "all"], default="all")
    parser.add_argument("--country", choices=["usa", "india", "all"], default="all")
    parser.add_argument("--verbose", "-v", action="store_true", help="print every measured field")
    args = parser.parse_args()

    errors: list = []
    report: list = []
    countries = ["usa", "india"] if args.country == "all" else [args.country]
    for country in countries:
        if args.platform in ("android", "all"):
            check_android(country, errors, report)
        if args.platform in ("ios", "all"):
            check_ios(country, errors, report)

    if args.verbose:
        for field, n, limit in report:
            print(f"{n:5d} / {limit:<5d} {field}")
    if errors:
        print("Store metadata problems:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1
    print(f"Store metadata OK ({len(report)} fields checked)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
