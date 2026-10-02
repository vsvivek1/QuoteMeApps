# Geo data import (postal codes and cities)

`geo_import.py` (Python 3.10+, stdlib only, needs `psql` on PATH) loads public datasets into
`public.postal_codes` and `public.cities`. Download the files by hand; the script never downloads
anything and never touches files bigger than you give it. Run it once per project
(`iwant-india-*` gets the Indian data, `iwant-usa-*` the US data). The upserts are idempotent and
keep seeded rows and the metro `priority` order.

| Dataset | Download | Licence | Command |
|---|---|---|---|
| India Post "All India Pincode Directory" (about 165k post offices, with lat/long) | https://data.gov.in/catalog/all-india-pincode-directory (resource "All India Pincode Directory till last month", CSV) | GODL-India | `india-post` |
| GeoNames postal codes, India (fallback or extra coverage) | https://download.geonames.org/export/zip/IN.zip | CC BY 4.0 | `geonames-postal --country IN` |
| GeoNames postal codes, USA (city, state and county names for ZIPs) | https://download.geonames.org/export/zip/US.zip | CC BY 4.0 | `geonames-postal --country US` |
| US Census Gazetteer, ZCTA (ZIP centroids) | https://www.census.gov/geographies/reference-files/time-series/geo/gazetteer-files.html → "ZIP Code Tabulation Areas" (for example `2024_Gaz_zcta_national.zip`) | Public domain | `zcta --names US.zip` |
| GeoNames cities (towns with population ≥ 1000 / 5000 / 15000) | https://download.geonames.org/export/dump/cities5000.zip (or `cities1000.zip`, `cities15000.zip`) | CC BY 4.0 | `geonames-cities` |
| GeoNames first-level admin names (state names for India) | https://download.geonames.org/export/dump/admin1CodesASCII.txt | CC BY 4.0 | `--admin1` |

Attribution: show "Contains GeoNames data (CC BY 4.0)" and "India Post / data.gov.in (GODL)"
on the website's about or legal page.

## India project

```bash
DB="postgresql://postgres:<password>@db.<india-ref>.supabase.co:5432/postgres"   # or the local stack URL
python3 tool/data/geo_import.py india-post ~/Downloads/pincode.csv --db "$DB"
python3 tool/data/geo_import.py geonames-postal ~/Downloads/IN.zip --country IN --db "$DB"   # optional: fills PINs without coordinates
python3 tool/data/geo_import.py geonames-cities ~/Downloads/cities5000.zip --country IN \
        --admin1 ~/Downloads/admin1CodesASCII.txt --min-population 5000 --db "$DB"
```

## USA project

```bash
DB="postgresql://postgres:<password>@db.<usa-ref>.supabase.co:5432/postgres"
python3 tool/data/geo_import.py zcta ~/Downloads/2024_Gaz_zcta_national.zip --names ~/Downloads/US.zip --db "$DB"
python3 tool/data/geo_import.py geonames-cities ~/Downloads/cities5000.zip --country US --min-population 5000 --db "$DB"
```

## Notes

- Without `--db` the script only writes the normalised CSV (`--out path.csv`, default a temp
  file), so you can check it first. With `--db` it runs `psql` with `\copy` into a temp table
  and upserts in one transaction.
- Postal codes: one row per code. The centroid is the median of the valid post-office
  coordinates (points outside the country's bounding box, `NA` and `0,0` are dropped). India:
  `city` = district, `district` = head or sub post-office locality. USA: `city` = GeoNames place,
  `district` = county. When a later file has no value, the earlier one is kept (`coalesce`), so
  the order above is safe to re-run.
- Cities are matched on `geoname_id`, then on the seeded `(name, state)`. `priority` (the
  outreach order of the top metros from the seeds) is never overwritten.
- State codes follow the seeds: ISO 3166-2:IN suffixes for India (`KA`, `MH`, `DL`, ...) and USPS
  codes for the USA.
- Use the direct database connection (port 5432) or the session pooler. The transaction pooler
  (port 6543) does not support `\copy`.
