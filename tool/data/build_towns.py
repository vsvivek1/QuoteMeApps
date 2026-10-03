#!/usr/bin/env python3
"""Build the town datasets for the websites' town pages (web/app_site/data/towns/generated/).

Stdlib only. Downloads three open-licensed GeoNames-derived datasets into a cache folder
(or uses the files already there), joins them and writes one gzipped JSON per country:

  python3 tool/data/build_towns.py                      # both countries
  python3 tool/data/build_towns.py --country india --cache ~/.cache/iwant-towns

Sources (all GeoNames data, CC BY 4.0, https://www.geonames.org; attribution on the sites'
open-source/credits page and in each output file's `sources`):

  cities.json (npm, monthly GeoNames export)  every populated place with population > 1000 or an
                                              admin seat, with admin1 (state) and admin2
                                              (district / county) codes and names
  cities-500-structured (npm, GeoNames 2023)  cities500.txt: GeoNames id, feature code, population
                                              and alternate names (native-script names)
  GeoNames postal codes (IN.zip, US.zip;      PIN / ZIP code, post office or USPS place name,
  JSON/CSV mirror zauberware/postal-codes-…)  state, district / county

The curated towns in web/app_site/data/towns/<country>.json (hand-written areas, aliases and
postal prefixes) are merged in: they keep their slug, areas and aliases.

Nothing in the output is a statistic about the app. Population is GeoNames' figure, shown on the
site only as a rounded band.
"""
from __future__ import annotations

import argparse
import csv
import difflib
import gzip
import hashlib
import io
import json
import math
import os
import re
import sys
import tarfile
import unicodedata
import urllib.request
import zipfile
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from geo_import import IN_CANONICAL, US_STATES, in_state  # noqa: E402  (same state names as the DB import)

REPO = Path(__file__).resolve().parents[2]
TOWNS_DIR = REPO / "web" / "app_site" / "data" / "towns"

SOURCES = {
    "cities_json": {
        "url": "https://registry.npmjs.org/cities.json/-/cities.json-1.1.65.tgz",
        "file": "cities.json-1.1.65.tgz",
        "title": "cities.json 1.1.65 (GeoNames cities export, populated places with population > 1000 or admin seats)",
        "licence": "CC BY 4.0",
        "home": "https://github.com/lutangar/cities.json",
    },
    "cities500": {
        "url": "https://registry.npmjs.org/cities-500-structured/-/cities-500-structured-1.0.1.tgz",
        "file": "cities-500-structured-1.0.1.tgz",
        "title": "GeoNames cities500 (2023 snapshot, via the cities-500-structured npm package)",
        "licence": "CC BY 4.0",
        "home": "https://download.geonames.org/export/dump/",
    },
    "postal_IN": {
        "url": "https://raw.githubusercontent.com/zauberware/postal-codes-json-xml-csv/master/data/IN.zip",
        "file": "postal-IN.zip",
        "title": "GeoNames postal codes, India (PIN codes and post offices, from India Post)",
        "licence": "CC BY 4.0",
        "home": "https://download.geonames.org/export/zip/",
    },
    "postal_US": {
        "url": "https://raw.githubusercontent.com/zauberware/postal-codes-json-xml-csv/master/data/US.zip",
        "file": "postal-US.zip",
        "title": "GeoNames postal codes, USA (ZIP codes, USPS place and county names)",
        "licence": "CC BY 4.0",
        "home": "https://download.geonames.org/export/zip/",
    },
}

CC = {"india": "IN", "usa": "US"}

# Scripts of each Indian state's main language (native-script town names from GeoNames).
SCRIPT_RANGES = {
    "deva": (0x0900, 0x097F), "beng": (0x0980, 0x09FF), "guru": (0x0A00, 0x0A7F), "gujr": (0x0A80, 0x0AFF),
    "orya": (0x0B00, 0x0B7F), "taml": (0x0B80, 0x0BFF), "telu": (0x0C00, 0x0C7F), "knda": (0x0C80, 0x0CFF),
    "mlym": (0x0D00, 0x0D7F),
}
LANG_SCRIPT = {"hi": "deva", "mr": "deva", "ne": "deva", "bn": "beng", "as": "beng", "pa": "guru", "gu": "gujr",
               "or": "orya", "ta": "taml", "te": "telu", "kn": "knda", "ml": "mlym"}
# Main language per state (second page language on the site). Absent: English only.
STATE_LANG_IN = {
    "Kerala": "ml", "Lakshadweep": "ml", "Tamil Nadu": "ta", "Puducherry": "ta", "Andhra Pradesh": "te",
    "Telangana": "te", "Karnataka": "kn", "Maharashtra": "mr", "Goa": "mr", "West Bengal": "bn", "Tripura": "bn",
    "Gujarat": "gu", "Dadra and Nagar Haveli and Daman and Diu": "gu", "Punjab": "pa", "Odisha": "or", "Assam": "as",
    "Sikkim": "ne", "Uttar Pradesh": "hi", "Bihar": "hi", "Madhya Pradesh": "hi", "Rajasthan": "hi", "Haryana": "hi",
    "Himachal Pradesh": "hi", "Uttarakhand": "hi", "Jharkhand": "hi", "Chhattisgarh": "hi", "Delhi": "hi",
    "Chandigarh": "hi", "Jammu and Kashmir": "hi", "Ladakh": "hi", "Andaman and Nicobar Islands": "hi",
    "Arunachal Pradesh": "hi",
}

DROP_FCODES = {"PPLH", "PPLQ", "PPLW", "PPLCH"}  # historical, abandoned, destroyed places
RESERVED_SLUGS = {"about", "sellers", "waitlist", "index", "contact", "legal", "quotes", "guides"}
AREA_POP = 100_000      # towns at least this big list localities (post offices / neighbourhoods)
METRO_POP = 250_000     # ... and include the PINs that share their head post office's first 4 digits
MAX_AREAS = 30


# --- helpers -------------------------------------------------------------------------------------

def fetch(key: str, cache: Path, offline: bool) -> Path:
    src = SOURCES[key]
    path = cache / src["file"]
    if path.exists() and path.stat().st_size > 0:
        return path
    if offline:
        sys.exit(f"{path} missing (run without --offline to download {src['url']})")
    cache.mkdir(parents=True, exist_ok=True)
    print(f"download {src['url']}", file=sys.stderr)
    with urllib.request.urlopen(src["url"], timeout=120) as r, open(path.with_suffix(".part"), "wb") as f:
        f.write(r.read())
    path.with_suffix(".part").rename(path)
    return path


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def tar_member(path: Path, suffix: str) -> bytes:
    with tarfile.open(path) as t:
        for m in t.getmembers():
            if m.name.endswith(suffix):
                return t.extractfile(m).read()
    sys.exit(f"{path}: no member ending in {suffix}")


def zip_csv(path: Path) -> list[dict]:
    with zipfile.ZipFile(path) as z:
        name = next(n for n in z.namelist() if n.endswith(".csv"))
        return list(csv.DictReader(io.TextIOWrapper(z.open(name), encoding="utf-8")))


def ascii_fold(s: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")


def norm(s: str) -> str:
    return re.sub(r"[^a-z0-9]", "", ascii_fold(s).lower())


def slugify(s: str) -> str:
    s = ascii_fold(s).lower().replace("&", " and ").replace("'", "").replace("’", "")
    return re.sub(r"[^a-z0-9]+", "-", s).strip("-")


def km(a: float, b: float, c: float, d: float) -> float:
    r = math.radians
    h = math.sin(r(c - a) / 2) ** 2 + math.cos(r(a)) * math.cos(r(c)) * math.sin(r(d - b) / 2) ** 2
    return 2 * 6371 * math.asin(min(1, math.sqrt(h)))


class Grid:
    """0.25 degree buckets for nearest-neighbour lookups."""

    def __init__(self, items, cell=0.25):
        self.cell = cell
        self.b = defaultdict(list)
        for it in items:
            self.b[(int(it["lat"] // cell), int(it["lng"] // cell))].append(it)

    def near(self, lat, lng, radius_km):
        r = int(radius_km / (111 * self.cell)) + 1
        i, j = int(lat // self.cell), int(lng // self.cell)
        out = []
        for a in range(i - r, i + r + 1):
            for b in range(j - r, j + r + 1):
                for it in self.b.get((a, b), ()):
                    d = km(lat, lng, it["lat"], it["lng"])
                    if d <= radius_km:
                        out.append((d, it))
        out.sort(key=lambda t: t[0])
        return out


def in_script(s: str, script: str) -> bool:
    lo, hi = SCRIPT_RANGES[script]
    letters = [c for c in s if unicodedata.category(c)[0] in "LM"]
    return bool(letters) and all(lo <= ord(c) <= hi for c in letters)


def native_name(alts: list[str], script: str | None) -> str | None:
    if not script:
        return None
    cands = []
    for a in alts:
        a = a.replace("‌", "").replace("‍", "").strip()
        if a and " " not in a and in_script(a, script):
            cands.append(a)
    if not cands:
        return None
    count = Counter(cands)
    # Most frequent spelling, then the shortest (drops "<name> district" style variants).
    return sorted(count, key=lambda a: (-count[a], len(a), a))[0]


def clean_district(s: str) -> str:
    s = re.sub(r"\s+(district|District|Division)$", "", s.strip())
    return s


def population_ok(p) -> int | None:
    return p if isinstance(p, int) and p > 0 else None


# --- postal --------------------------------------------------------------------------------------

OFFICE_SUFFIX = re.compile(
    r"[\s.]*(\b(h\.?\s?o|s\.?\s?o|b\.?\s?o|g\.?\s?p\.?\s?o|po)\b\.?)+$", re.I)
OFFICE_NOISE = re.compile(
    r"\b(parcel|foreign|sorting|mail|court|secretariat|bldg|building|offices?|complex|legislators|"
    r"rms|ncr|tso|hpo|mdg|ndg|naval|air ?force|army|cantt?\b|cantonment|depot|camp|university|college|"
    r"institute|hospital|airport|station|r\.?\s?s\.?$|road$|bazar$|bazaar$|market$|corporation)", re.I)


def office_base(place: str) -> str:
    p = OFFICE_SUFFIX.sub("", place.strip())
    p = re.sub(r"\s+(town|city|east|west|north|south|central)$", "", p, flags=re.I)
    return norm(p)


def office_display(place: str) -> str:
    p = OFFICE_SUFFIX.sub("", place.strip()).strip(" .")
    p = re.sub(r"\s{2,}", " ", p)
    return p


def district_match(a: str, b: str) -> bool:
    x, y = norm(a), norm(b)
    return bool(x and y) and (x == y or x.startswith(y) or y.startswith(x) or x[:5] == y[:5])


# --- build ---------------------------------------------------------------------------------------

def load_curated(country: str) -> list[dict]:
    return json.loads((TOWNS_DIR / f"{country}.json").read_text())["towns"]


def build(country: str, cache: Path, offline: bool) -> dict:
    cc = CC[country]
    paths = {k: fetch(k, cache, offline) for k in ("cities_json", "cities500", f"postal_{cc}")}

    cities = json.loads(tar_member(paths["cities_json"], "/cities.json"))
    admin1 = {x["code"]: x["name"] for x in json.loads(tar_member(paths["cities_json"], "/admin1.json"))}
    admin2 = {x["code"]: x["name"] for x in json.loads(tar_member(paths["cities_json"], "/admin2.json"))}
    base = [c for c in cities if c["country"] == cc]

    g500 = []
    for line in tar_member(paths["cities500"], "/cities500.txt").decode("utf-8").splitlines():
        f = line.split("\t")
        if len(f) < 19 or f[8] != cc:
            continue
        g500.append({
            "id": int(f[0]), "name": f[1], "ascii": f[2], "alts": [a for a in f[3].split(",") if a],
            "lat": float(f[4]), "lng": float(f[5]), "fcode": f[7], "admin1": f[10],
            "pop": int(f[14] or 0),
        })
    g500_grid = Grid(g500)

    def state_name(code: str) -> str | None:
        if cc == "US":
            return US_STATES.get(code) if code in US_STATES and code not in {"PR", "GU", "VI", "AS", "MP"} else None
        raw = admin1.get(f"IN.{code}")
        if not raw:
            return None
        name, scode = in_state(raw)
        return IN_CANONICAL.get(scode, name)

    # 1. Towns from cities.json, enriched with cities500 (id, feature code, population, alt names).
    towns, sections = [], []
    for c in base:
        lat, lng = float(c["lat"]), float(c["lng"])
        st = state_name(c["admin1"])
        if not st:
            continue
        key = norm(c["name"])
        match = None
        near = [(d, g) for d, g in g500_grid.near(lat, lng, 3) if g["admin1"] == c["admin1"]]
        for d, g in near:
            if norm(g["name"]) == key or norm(g["ascii"]) == key or any(norm(a) == key for a in g["alts"]):
                match = g
                break
        if not match:
            # Same point under another name (Kochi / Cochin) or a spelling variant (Mancherial / Mancheral).
            for d, g in near:
                if d <= 0.3 or (d <= 2 and difflib.SequenceMatcher(None, key, norm(g["ascii"])).ratio() >= 0.8):
                    match = g
                    break
        if match and match["fcode"] in DROP_FCODES:
            continue
        district = admin2.get(f"{cc}.{c['admin1']}.{c['admin2']}", "") if c.get("admin2") else ""
        name = c["name"]
        if cc == "IN":
            name = match["ascii"] if match and match["ascii"] else ascii_fold(name)
            district = ascii_fold(clean_district(district))
        t = {
            "name": name.strip(),
            "state": st,
            "admin1": c["admin1"],
            "district": district,
            "lat": round(lat, 4),
            "lng": round(lng, 4),
            "pop": population_ok(match["pop"]) if match else None,
            "gid": match["id"] if match else None,
            "alts": match["alts"] if match else [],
            "ascii": match["ascii"] if match else ascii_fold(name),
        }
        # Washington, DC is one city: GeoNames lists its neighbourhoods (Shaw, Georgetown, ...) as places.
        dc_part = cc == "US" and c["admin1"] == "DC" and not norm(name).startswith("washington")
        (sections if dc_part or (match and match["fcode"] == "PPLX") else towns).append(t)

    # The same GeoNames id twice (cities.json duplicates): keep the first.
    seen, uniq = set(), []
    for t in towns:
        if t["gid"] and t["gid"] in seen:
            continue
        seen.add(t["gid"])
        uniq.append(t)
    towns = uniq

    # 2. Sections of a populated place (PPLX, e.g. neighbourhoods) become areas of the nearest bigger town.
    town_grid = Grid(towns)
    for s in sections:
        host = next((t for d, t in town_grid.near(s["lat"], s["lng"], 25)
                     if t["state"] == s["state"] and (t["pop"] or 0) >= 50_000), None)
        if host:
            host.setdefault("pplx", []).append(s["name"])

    # 3. Curated towns: keep slug, areas, aliases; matched by name/alias near the same place.
    curated = load_curated(country)
    for cur in curated:
        names = {norm(cur["name"]), norm(cur["slug"].replace("-", " ")), *(norm(a) for a in cur.get("aka", []))}
        cands = [t for d, t in town_grid.near(cur["lat"], cur["lng"], 30)
                 if t["state"] == cur["state"] or norm(t["state"]) == norm(cur["state"])]
        hit = [t for t in cands if norm(t["name"]) in names or norm(t["ascii"]) in names
               or any(norm(a) in names for a in t["alts"] if a.isascii())]
        hit.sort(key=lambda t: -(t["pop"] or 0))
        if hit:
            t = hit[0]
        else:
            t = {"name": cur["name"], "state": cur["state"], "admin1": None, "district": "", "lat": cur["lat"],
                 "lng": cur["lng"], "pop": None, "gid": None, "alts": [], "ascii": cur["name"]}
            towns.append(t)
            print(f"  curated {cur['slug']}: no GeoNames match, added as is", file=sys.stderr)
        t.update({"name": cur["name"], "lat": cur["lat"], "lng": cur["lng"], "curated": cur})

    # 4. Postal codes and areas.
    rows = zip_csv(paths[f"postal_{cc}"])
    offices = []
    for r in rows:
        try:
            lat, lng = float(r["latitude"]), float(r["longitude"])
        except ValueError:
            continue
        if cc == "IN":
            st = in_state(r["state"])
            st = IN_CANONICAL.get(st[1], st[0])
        else:
            st = US_STATES.get(r["state_code"])
        offices.append({"pin": r["zipcode"], "place": r["place"], "base": office_base(r["place"]) if cc == "IN" else norm(r["place"]),
                        "state": st, "district": r["province"], "lat": lat, "lng": lng})
    by_name = defaultdict(list)
    by_prefix = defaultdict(list)
    by_pin = defaultdict(list)
    for o in offices:
        by_name[(o["state"], o["base"])].append(o)
        by_prefix[(o["state"], o["pin"][:4])].append(o)
        by_pin[o["pin"]].append(o)
    office_grid = Grid(offices)
    postal_states = {"Ladakh": ["Ladakh", "Jammu and Kashmir"]}

    stats = Counter()
    for t in towns:
        names = {norm(t["name"]), norm(t["ascii"])}
        if cc == "US":
            n = t["name"]
            for a, b in (("Saint ", "St "), ("St. ", "St "), ("Mount ", "Mt "), ("Fort ", "Ft ")):
                if n.startswith(a):
                    names.add(norm(b + n[len(a):]))
        cur = t.get("curated")
        if cur:
            names |= {norm(a) for a in cur.get("aka", [])}
        if cc == "IN":
            names |= {norm(a) for a in t["alts"] if a.isascii() and len(a) >= 5 and not a.isupper()}
        names.discard("")
        states = postal_states.get(t["state"], [t["state"]])
        matched = []
        for st in states:
            for nm in names:
                for o in by_name.get((st, nm), ()):
                    near = km(t["lat"], t["lng"], o["lat"], o["lng"])
                    if cc == "US":
                        ok = near <= 40
                    else:
                        ok = near <= 30 or (t["district"] and district_match(t["district"], o["district"]))
                    if ok:
                        matched.append(o)
        pins = {o["pin"] for o in matched}
        big = (t["pop"] or 0) >= METRO_POP or bool(cur)
        if cc == "IN" and big:
            heads = [o for o in matched if re.search(r"\b(h\.?\s?o|g\.?\s?p\.?\s?o)\b", o["place"], re.I)]
            for h in heads:
                for o in by_prefix[(h["state"], h["pin"][:4])]:
                    if district_match(h["district"], o["district"]):
                        pins.add(o["pin"])
        if cur and cur.get("postal_prefixes"):
            # Curated towns: only codes under their hand-checked prefixes.
            pins = {p for p in pins if p[:3] in cur["postal_prefixes"]}
        mode = "name" if pins else None
        if not pins:
            near = [o for d, o in office_grid.near(t["lat"], t["lng"], 5) if o["state"] in states]
            if near:
                pins = {near[0]["pin"]}
                mode = "near"
        t["postal"] = sorted(pins)
        t["postal_mode"] = mode
        stats[mode or "none"] += 1
        # District from the post offices when GeoNames has none.
        if not t["district"] and pins:
            dc = Counter(o["district"] for p in pins for o in by_pin[p])
            if dc:
                t["district"] = clean_district(dc.most_common(1)[0][0])

        areas: list[str] = []
        if cur and cur.get("areas"):
            areas = list(cur["areas"])
        elif (t["pop"] or 0) >= AREA_POP:
            if cc == "IN" and mode == "name":
                own = names
                for p in t["postal"]:
                    for o in by_pin[p]:
                        nm = office_display(o["place"])
                        if not nm or OFFICE_NOISE.search(nm) or norm(nm) in own or re.search(r"\d", nm):
                            continue
                        areas.append(nm)
            areas += t.get("pplx", [])
        seen_a, out = set(), []
        for a in areas:
            k = norm(a)
            if k and k not in seen_a and k not in names:
                seen_a.add(k)
                out.append(a)
        t["areas"] = out[:MAX_AREAS]
    print(f"  postal codes: {dict(stats)}", file=sys.stderr)

    # 5. Slugs: unique within a state; duplicates get the district / county as suffix.
    by_state = defaultdict(list)
    for t in towns:
        by_state[t["state"]].append(t)
    for st, ts in by_state.items():
        ts.sort(key=lambda t: (not t.get("curated"), -(t["pop"] or 0), t["name"]))
        used = set()
        for t in ts:
            if t.get("curated"):
                s = t["curated"]["slug"]
            else:
                s = slugify(t["name"]) or "town"
                if s in RESERVED_SLUGS:
                    s = f"{s}-town"
                if s in used and t["district"]:
                    s = f"{s}-{slugify(re.sub(r' (County|Parish|Borough|Census Area|Municipality|City and Borough)$', '', t['district']))}"
            n, b = 2, s
            while s in used:
                s = f"{b}-{n}"
                n += 1
            used.add(s)
            t["slug"] = s

    states = sorted({t["state"] for t in towns})
    state_rows = []
    for st in states:
        row = {"slug": slugify(st), "name": st}
        if cc == "US":
            row["code"] = next(k for k, v in US_STATES.items() if v == st)
        else:
            row["code"] = next((k for k, v in IN_CANONICAL.items() if v == st), "")
            if STATE_LANG_IN.get(st):
                row["lang"] = STATE_LANG_IN[st]
        state_rows.append(row)
    state_slug = {r["name"]: r["slug"] for r in state_rows}
    state_lang = {r["name"]: r.get("lang") for r in state_rows}
    assert len({r["slug"] for r in state_rows}) == len(state_rows)

    out_towns = []
    for t in sorted(towns, key=lambda t: (t["state"], -(t["pop"] or 0), t["slug"])):
        lang = state_lang.get(t["state"])
        row = {
            "s": t["slug"],
            "n": t["name"],
            "st": state_slug[t["state"]],
            "d": t["district"] or None,
            "la": t["lat"],
            "lo": t["lng"],
            "p": t["pop"],
            "z": t["postal"],
            "zm": t["postal_mode"],
            "a": t["areas"] or None,
            "nn": ((t.get("curated") or {}).get("native") or native_name(t["alts"], LANG_SCRIPT.get(lang))) if lang else None,
            "aka": (t["curated"].get("aka") or None) if t.get("curated") else None,
            "c": 1 if t.get("curated") else None,
            "g": t["gid"],
        }
        out_towns.append({k: v for k, v in row.items() if v is not None})

    return {
        "version": 1,
        "country": country,
        "_comment": "Generated by tool/data/build_towns.py from GeoNames data (CC BY 4.0) plus the curated towns in "
                    f"../{country}.json. Do not edit by hand; re-run the script. Keys: s slug (unique within the state), "
                    "n name, nn native-script name, st state slug, d district/county, la/lo centre, p GeoNames population, "
                    "z postal codes, zm how they were matched (name: post office or USPS place name; near: nearest "
                    "post office within 5 km), a areas/localities, aka other names, c curated, g GeoNames id.",
        "sources": [
            {"title": SOURCES[k]["title"], "licence": SOURCES[k]["licence"], "url": SOURCES[k]["home"],
             "file": SOURCES[k]["url"], "sha256": sha256(paths[k])}
            for k in ("cities_json", "cities500", f"postal_{cc}")
        ],
        "states": state_rows,
        "towns": out_towns,
    }


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--country", choices=["india", "usa"], action="append")
    ap.add_argument("--cache", default=os.path.expanduser("~/.cache/iwant-towns"))
    ap.add_argument("--offline", action="store_true", help="never download; use files in --cache only")
    ap.add_argument("--out", default=str(TOWNS_DIR / "generated"))
    a = ap.parse_args()
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    for country in a.country or ["india", "usa"]:
        print(f"{country}:", file=sys.stderr)
        data = build(country, Path(a.cache), a.offline)
        raw = json.dumps(data, ensure_ascii=False, separators=(",", ":"), sort_keys=False).encode()
        target = out / f"{country}.json.gz"
        # mtime=0: the same input gives byte-identical output (clean git diffs).
        with open(target, "wb") as f, gzip.GzipFile(fileobj=f, mode="wb", mtime=0, compresslevel=9) as gz:
            gz.write(raw)
        t = data["towns"]
        print(f"  {len(t)} towns in {len(data['states'])} states, {sum(1 for x in t if x.get('z'))} with postal codes, "
              f"{sum(1 for x in t if x.get('a'))} with areas, {sum(1 for x in t if x.get('nn'))} with native names; "
              f"{target} {target.stat().st_size // 1024} KB ({len(raw) // 1024} KB raw)", file=sys.stderr)


if __name__ == "__main__":
    main()
