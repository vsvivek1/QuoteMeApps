#!/usr/bin/env python3
"""Load postal codes and cities into Supabase (public.postal_codes, public.cities).

Stdlib only. Each sub-command parses one public dataset, writes a normalised
CSV and, with --db, loads it through `psql \\copy` + an idempotent upsert.
Download the source files yourself (see tool/data/README.md); nothing here
downloads large files.

  python3 tool/data/geo_import.py india-post   pincode.csv              --db "$DB_URL"
  python3 tool/data/geo_import.py geonames-postal IN.zip --country IN   --db "$DB_URL"
  python3 tool/data/geo_import.py zcta 2023_Gaz_zcta_national.zip --names US.zip --db "$DB_URL"
  python3 tool/data/geo_import.py geonames-cities cities5000.zip --country US \\
          --admin1 admin1CodesASCII.txt --min-population 5000 --db "$DB_URL"

Postal codes: existing rows are updated (centroid, names); seeded rows stay
when a dataset lacks a code. Cities: matched on geoname_id, else on
(lower(name), state); `priority` set by the seeds (top metros) is kept.
"""
from __future__ import annotations

import argparse
import csv
import io
import os
import re
import statistics
import subprocess
import sys
import tempfile
import zipfile
from collections import Counter, defaultdict
from typing import Iterable, Iterator

# --- state names <-> codes ----------------------------------------------------------------------

IN_STATES = {
    "andaman and nicobar islands": "AN", "andaman and nicobar": "AN", "andhra pradesh": "AP", "arunachal pradesh": "AR", "assam": "AS",
    "bihar": "BR", "chandigarh": "CH", "chhattisgarh": "CT", "dadra and nagar haveli and daman and diu": "DH",
    "dadra and nagar haveli": "DH", "daman and diu": "DH", "delhi": "DL", "nct of delhi": "DL", "goa": "GA",
    "gujarat": "GJ", "haryana": "HR", "himachal pradesh": "HP", "jammu and kashmir": "JK", "jharkhand": "JH",
    "karnataka": "KA", "kerala": "KL", "ladakh": "LA", "lakshadweep": "LD", "madhya pradesh": "MP",
    "maharashtra": "MH", "manipur": "MN", "meghalaya": "ML", "mizoram": "MZ", "nagaland": "NL", "odisha": "OR",
    "orissa": "OR", "puducherry": "PY", "pondicherry": "PY", "punjab": "PB", "rajasthan": "RJ", "sikkim": "SK",
    "tamil nadu": "TN", "telangana": "TG", "tripura": "TR", "uttar pradesh": "UP", "uttarakhand": "UT",
    "uttaranchal": "UT", "west bengal": "WB",
}
IN_CANONICAL = {
    "AN": "Andaman and Nicobar Islands", "AP": "Andhra Pradesh", "AR": "Arunachal Pradesh", "AS": "Assam",
    "BR": "Bihar", "CH": "Chandigarh", "CT": "Chhattisgarh", "DH": "Dadra and Nagar Haveli and Daman and Diu",
    "DL": "Delhi", "GA": "Goa", "GJ": "Gujarat", "HR": "Haryana", "HP": "Himachal Pradesh", "JK": "Jammu and Kashmir",
    "JH": "Jharkhand", "KA": "Karnataka", "KL": "Kerala", "LA": "Ladakh", "LD": "Lakshadweep", "MP": "Madhya Pradesh",
    "MH": "Maharashtra", "MN": "Manipur", "ML": "Meghalaya", "MZ": "Mizoram", "NL": "Nagaland", "OR": "Odisha",
    "PY": "Puducherry", "PB": "Punjab", "RJ": "Rajasthan", "SK": "Sikkim", "TN": "Tamil Nadu", "TG": "Telangana",
    "TR": "Tripura", "UP": "Uttar Pradesh", "UT": "Uttarakhand", "WB": "West Bengal",
}
US_STATES = {
    "AL": "Alabama", "AK": "Alaska", "AZ": "Arizona", "AR": "Arkansas", "CA": "California", "CO": "Colorado",
    "CT": "Connecticut", "DE": "Delaware", "DC": "District of Columbia", "FL": "Florida", "GA": "Georgia",
    "HI": "Hawaii", "ID": "Idaho", "IL": "Illinois", "IN": "Indiana", "IA": "Iowa", "KS": "Kansas",
    "KY": "Kentucky", "LA": "Louisiana", "ME": "Maine", "MD": "Maryland", "MA": "Massachusetts", "MI": "Michigan",
    "MN": "Minnesota", "MS": "Mississippi", "MO": "Missouri", "MT": "Montana", "NE": "Nebraska", "NV": "Nevada",
    "NH": "New Hampshire", "NJ": "New Jersey", "NM": "New Mexico", "NY": "New York", "NC": "North Carolina",
    "ND": "North Dakota", "OH": "Ohio", "OK": "Oklahoma", "OR": "Oregon", "PA": "Pennsylvania", "RI": "Rhode Island",
    "SC": "South Carolina", "SD": "South Dakota", "TN": "Tennessee", "TX": "Texas", "UT": "Utah", "VT": "Vermont",
    "VA": "Virginia", "WA": "Washington", "WV": "West Virginia", "WI": "Wisconsin", "WY": "Wyoming",
    "PR": "Puerto Rico", "GU": "Guam", "VI": "U.S. Virgin Islands", "AS": "American Samoa", "MP": "Northern Mariana Islands",
}

IN_BOUNDS = (6.0, 37.6, 68.0, 97.5)  # lat min/max, lng min/max (rejects 0,0 and swapped coordinates)
US_BOUNDS = (17.0, 72.0, -180.0, -64.0)


def in_state(name: str) -> tuple[str, str]:
    key = re.sub(r"\s+", " ", name.replace("&", "and").strip().lower())
    code = IN_STATES.get(key, "")
    return (IN_CANONICAL.get(code, name.strip().title()), code)


def titlecase(s: str) -> str:
    """BANGALORE -> Bangalore; keeps abbreviations such as G.P.O. and mixed case."""
    return " ".join(
        w if "." in w or not (w.isupper() or w.islower()) else w.capitalize() for w in s.strip().split()
    )


def num(s: str | None) -> float | None:
    try:
        v = float(str(s).strip())
    except (TypeError, ValueError):
        return None
    return v if v == v else None  # NaN


def within(lat: float | None, lng: float | None, b: tuple[float, float, float, float]) -> bool:
    return lat is not None and lng is not None and b[0] <= lat <= b[1] and b[2] <= lng <= b[3]


def open_text(path: str, member_hint: str | None = None) -> io.TextIOBase:
    """Opens a plain or zipped (first matching .txt/.csv member) text file."""
    if path.lower().endswith(".zip"):
        z = zipfile.ZipFile(path)
        names = [n for n in z.namelist() if n.lower().endswith((".txt", ".csv")) and "readme" not in n.lower()]
        if member_hint:
            names = [n for n in names if member_hint.lower() in n.lower()] or names
        if not names:
            sys.exit(f"{path}: no .txt/.csv member")
        return io.TextIOWrapper(z.open(names[0]), encoding="utf-8-sig", newline="")
    return open(path, encoding="utf-8-sig", newline="", errors="replace")


# --- parsers ------------------------------------------------------------------------------------

POSTAL_COLS = ["code", "lat", "lng", "city", "district", "state", "state_code", "source"]
CITY_COLS = ["geoname_id", "name", "ascii_name", "slug", "state", "state_code", "population", "lat", "lng", "timezone"]


def parse_india_post(path: str) -> Iterator[dict]:
    """data.gov.in 'All India Pincode Directory' CSV (one row per post office)."""
    groups: dict[str, list[dict]] = defaultdict(list)
    with open_text(path) as f:
        reader = csv.DictReader(f)
        cols = {c.lower().strip(): c for c in reader.fieldnames or []}
        def col(row: dict, *names: str) -> str:
            for n in names:
                if n in cols:
                    return (row.get(cols[n]) or "").strip()
            return ""
        for row in reader:
            pin = re.sub(r"\D", "", col(row, "pincode"))
            if len(pin) != 6:
                continue
            groups[pin].append({
                "office": col(row, "officename", "office name"),
                "type": col(row, "officetype", "office type").upper(),
                "district": col(row, "district", "districtname"),
                "state": col(row, "statename", "state name", "state"),
                "lat": num(col(row, "latitude")),
                "lng": num(col(row, "longitude")),
            })
    for pin, rows in groups.items():
        pts = [(r["lat"], r["lng"]) for r in rows if within(r["lat"], r["lng"], IN_BOUNDS)]
        lat = statistics.median(p[0] for p in pts) if pts else None
        lng = statistics.median(p[1] for p in pts) if pts else None
        district = Counter(titlecase(r["district"]) for r in rows if r["district"]).most_common(1)
        state_name, state_code = in_state(Counter(r["state"] for r in rows if r["state"]).most_common(1)[0][0]) \
            if any(r["state"] for r in rows) else ("", "")
        # locality: the head / sub post office name without its suffix
        main = sorted(rows, key=lambda r: {"H.O": 0, "HO": 0, "S.O": 1, "SO": 1}.get(r["type"], 2))[0]
        locality = re.sub(r"\s+(H\.?O|S\.?O|B\.?O)\.?$", "", main["office"], flags=re.I).strip()
        yield {
            "code": pin, "lat": lat, "lng": lng,
            "city": district[0][0] if district else "", "district": titlecase(locality),
            "state": state_name, "state_code": state_code, "source": "india_post",
        }


def parse_geonames_postal(path: str, country: str) -> Iterator[dict]:
    """GeoNames postal code dump (IN.zip / US.zip / allCountries.zip), tab separated."""
    groups: dict[str, list[list[str]]] = defaultdict(list)
    with open_text(path, f"{country}.txt") as f:
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) < 11 or p[0] != country:
                continue
            groups[p[1].strip()].append(p)
    bounds = IN_BOUNDS if country == "IN" else US_BOUNDS
    for code, rows in groups.items():
        if country == "IN" and not re.fullmatch(r"\d{6}", code):
            continue
        if country == "US" and not re.fullmatch(r"\d{5}", code):
            continue
        pts = [(num(r[9]), num(r[10])) for r in rows]
        pts = [p for p in pts if within(p[0], p[1], bounds)]
        first = rows[0]
        if country == "US":
            state_code = first[4].strip()
            state = US_STATES.get(state_code, first[3].strip())
            city, district = first[2].strip(), first[5].strip()  # place, county
        else:
            state, state_code = in_state(first[3])
            city = titlecase(first[5] or first[2])  # district (admin2), else place
            district = titlecase(first[2])
        yield {
            "code": code,
            "lat": statistics.median(p[0] for p in pts) if pts else None,
            "lng": statistics.median(p[1] for p in pts) if pts else None,
            "city": city, "district": district, "state": state, "state_code": state_code,
            "source": "geonames",
        }


def parse_zcta(path: str, names_path: str | None) -> Iterator[dict]:
    """US Census Gazetteer ZCTA file: GEOID, ..., INTPTLAT, INTPTLONG (tab separated).
    ZCTA internal points are better centroids than GeoNames; names come from GeoNames US postal."""
    names = {r["code"]: r for r in parse_geonames_postal(names_path, "US")} if names_path else {}
    with open_text(path, "zcta") as f:
        reader = csv.reader(f, delimiter="\t")
        header = [h.strip().upper() for h in next(reader)]
        i_geo, i_lat, i_lng = header.index("GEOID"), header.index("INTPTLAT"), header.index("INTPTLONG")
        for row in reader:
            if len(row) <= max(i_geo, i_lat, i_lng):
                continue
            code = row[i_geo].strip().zfill(5)
            lat, lng = num(row[i_lat]), num(row[i_lng])
            n = names.get(code, {})
            if not within(lat, lng, US_BOUNDS) and n.get("lat") is None:
                continue  # no usable centroid
            yield {
                "code": code,
                "lat": lat if within(lat, lng, US_BOUNDS) else n.get("lat"),
                "lng": lng if within(lat, lng, US_BOUNDS) else n.get("lng"),
                "city": n.get("city", ""), "district": n.get("district", ""),
                "state": n.get("state", ""), "state_code": n.get("state_code", ""), "source": "census_zcta",
            }


def parse_admin1(path: str | None, country: str) -> dict[str, str]:
    out: dict[str, str] = {}
    if not path:
        return out
    with open_text(path) as f:
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) >= 2 and p[0].startswith(country + "."):
                out[p[0].split(".", 1)[1]] = p[1]
    return out


def slugify(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")


def parse_geonames_cities(path: str, country: str, admin1_path: str | None, min_population: int) -> Iterator[dict]:
    """GeoNames cities1000/5000/15000 (or allCountries) dump."""
    admin1 = parse_admin1(admin1_path, country)
    with open_text(path) as f:
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) < 19 or p[8] != country or p[6] != "P":
                continue
            pop = int(p[14] or 0)
            if pop < min_population:
                continue
            a1 = p[10]
            if country == "US":
                state_code, state = a1, US_STATES.get(a1, admin1.get(a1, a1))
            else:
                state, state_code = in_state(admin1.get(a1, ""))
            yield {
                "geoname_id": p[0], "name": p[1], "ascii_name": p[2], "slug": slugify(p[2] or p[1]),
                "state": state, "state_code": state_code, "population": pop,
                "lat": num(p[4]), "lng": num(p[5]), "timezone": p[17],
            }


# --- output + load ------------------------------------------------------------------------------

def write_csv(rows: Iterable[dict], cols: list[str], out: str) -> int:
    n = 0
    with open(out, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=cols, extrasaction="ignore")
        w.writeheader()
        for r in rows:
            w.writerow({k: ("" if r.get(k) is None else r.get(k)) for k in cols})
            n += 1
    return n


POSTAL_SQL = """
create temp table _pc (code text, lat float8, lng float8, city text, district text, state text, state_code text, source text);
\\copy _pc from '{csv}' with (format csv, header true)
insert into public.postal_codes (code, centroid, city, district, state, state_code, source)
select distinct on (code) code,
       case when lat is not null and lng is not null
            then extensions.st_setsrid(extensions.st_makepoint(lng, lat), 4326)::extensions.geography end,
       nullif(city, ''), nullif(district, ''), nullif(state, ''), nullif(state_code, ''), source
  from _pc where code <> ''
on conflict (code) do update set
  centroid = coalesce(excluded.centroid, public.postal_codes.centroid),
  city = coalesce(excluded.city, public.postal_codes.city),
  district = coalesce(excluded.district, public.postal_codes.district),
  state = coalesce(excluded.state, public.postal_codes.state),
  state_code = coalesce(excluded.state_code, public.postal_codes.state_code),
  source = excluded.source;
select count(*) as postal_codes_total from public.postal_codes;
"""

CITY_SQL = """
create temp table _c (geoname_id bigint, name text, ascii_name text, slug text, state text, state_code text,
                      population bigint, lat float8, lng float8, timezone text);
\\copy _c from '{csv}' with (format csv, header true)
-- 1) rows already linked by geoname_id; 2) seeded rows matched by name + state (keeps priority)
update public.cities c set name = s.name, ascii_name = s.ascii_name, slug = coalesce(c.slug, s.slug),
       state = s.state, state_code = s.state_code, population = s.population, timezone = s.timezone,
       centroid = extensions.st_setsrid(extensions.st_makepoint(s.lng, s.lat), 4326)::extensions.geography
  from _c s where c.geoname_id = s.geoname_id;
update public.cities c set geoname_id = s.geoname_id, population = s.population, timezone = coalesce(c.timezone, s.timezone),
       state_code = coalesce(c.state_code, s.state_code)
  from (select distinct on (lower(name), state) * from _c order by lower(name), state, population desc) s
 where c.geoname_id is null and lower(c.name) = lower(s.name) and c.state = s.state
   and not exists (select 1 from public.cities x where x.geoname_id = s.geoname_id);
insert into public.cities (geoname_id, name, ascii_name, slug, state, state_code, population, centroid, timezone)
select s.geoname_id, s.name, s.ascii_name, s.slug, s.state, s.state_code, s.population,
       extensions.st_setsrid(extensions.st_makepoint(s.lng, s.lat), 4326)::extensions.geography, s.timezone
  from _c s
 where not exists (select 1 from public.cities c where c.geoname_id = s.geoname_id);
select count(*) as cities_total, count(*) filter (where priority is not null) as priority_cities from public.cities;
"""


def load(db: str, sql_template: str, csv_path: str) -> None:
    sql = sql_template.format(csv=csv_path.replace("'", "''"))
    with tempfile.NamedTemporaryFile("w", suffix=".sql", delete=False) as f:
        f.write("\\set ON_ERROR_STOP on\nbegin;\n" + sql + "commit;\n")
        script = f.name
    try:
        subprocess.run(["psql", db, "-X", "-q", "-f", script], check=True)
    finally:
        os.unlink(script)


def main(argv: list[str] | None = None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--out", help="normalised CSV path (default: a temp file)")
    common.add_argument("--db", help="Postgres URL; when set, load with psql \\copy + upsert")

    p = sub.add_parser("india-post", parents=[common], help="data.gov.in All India Pincode Directory CSV")
    p.add_argument("path")
    p = sub.add_parser("geonames-postal", parents=[common], help="GeoNames postal codes (IN.zip / US.zip)")
    p.add_argument("path")
    p.add_argument("--country", required=True, choices=["IN", "US"])
    p = sub.add_parser("zcta", parents=[common], help="US Census Gazetteer ZCTA file (+ GeoNames US names)")
    p.add_argument("path")
    p.add_argument("--names", help="GeoNames US.zip / US.txt for city + state names")
    p = sub.add_parser("geonames-cities", parents=[common], help="GeoNames cities1000/5000/15000")
    p.add_argument("path")
    p.add_argument("--country", required=True, choices=["IN", "US"])
    p.add_argument("--admin1", help="admin1CodesASCII.txt (needed for Indian state names)")
    p.add_argument("--min-population", type=int, default=5000)
    a = ap.parse_args(argv)

    if a.cmd == "india-post":
        rows, cols, sql = parse_india_post(a.path), POSTAL_COLS, POSTAL_SQL
    elif a.cmd == "geonames-postal":
        rows, cols, sql = parse_geonames_postal(a.path, a.country), POSTAL_COLS, POSTAL_SQL
    elif a.cmd == "zcta":
        rows, cols, sql = parse_zcta(a.path, a.names), POSTAL_COLS, POSTAL_SQL
    else:
        if a.country == "IN" and not a.admin1:
            sys.exit("--admin1 admin1CodesASCII.txt is required for India (state names)")
        rows, cols, sql = parse_geonames_cities(a.path, a.country, a.admin1, a.min_population), CITY_COLS, CITY_SQL

    out = a.out or tempfile.mkstemp(prefix=f"iwant-{a.cmd}-", suffix=".csv")[1]
    n = write_csv(rows, cols, out)
    print(f"{a.cmd}: {n} rows -> {out}", file=sys.stderr)
    if a.db:
        load(a.db, sql, out)


if __name__ == "__main__":
    main()
