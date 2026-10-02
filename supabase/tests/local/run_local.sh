#!/usr/bin/env bash
# Local validation harness without Docker / Supabase CLI.
#
# Starts (or reuses) a throwaway Postgres 16 cluster with PostGIS + pgTAP,
# installs minimal Supabase shims (auth / storage schemas, API roles,
# realtime publication), applies every migration, the shared seed, one
# country seed + demo data, then runs the pgTAP suite with pg_prove.
#
# Usage:
#   supabase/tests/local/run_local.sh                # india and usa
#   supabase/tests/local/run_local.sh india          # one country
#   KEEP_CLUSTER=1 supabase/tests/local/run_local.sh # leave cluster running
#
# Env: PGBIN (default: pg_config --bindir), PGPORT (default 55432),
#      PGWORK (cluster dir, default /tmp/iwant-pg-$PGPORT), NO_DEMO=1 to skip demo data.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUPA="$(cd "$HERE/../.." && pwd)"
COUNTRIES=("$@")
[ ${#COUNTRIES[@]} -eq 0 ] && COUNTRIES=(india usa)

PGBIN="${PGBIN:-$(pg_config --bindir 2>/dev/null || echo /usr/lib/postgresql/16/bin)}"
PORT="${PGPORT:-55432}"
WORK="${PGWORK:-/tmp/iwant-pg-$PORT}"
DATA="$WORK/data"

# Postgres refuses to run as root: use the postgres OS user when we are root.
if [ "$(id -u)" = "0" ]; then
  RUN_AS=(runuser -u postgres --)
  OWNER=postgres
else
  RUN_AS=()
  OWNER="$(id -un)"
fi

start_cluster() {
  mkdir -p "$WORK"
  chown "$OWNER" "$WORK" 2>/dev/null || true
  if [ ! -f "$DATA/PG_VERSION" ]; then
    echo "==> initdb $DATA"
    "${RUN_AS[@]}" "$PGBIN/initdb" -D "$DATA" -U postgres --auth=trust -E UTF8 --locale=C.UTF-8 >/dev/null
  fi
  if ! "${RUN_AS[@]}" "$PGBIN/pg_ctl" -D "$DATA" status >/dev/null 2>&1; then
    echo "==> starting postgres on port $PORT"
    "${RUN_AS[@]}" "$PGBIN/pg_ctl" -D "$DATA" -l "$WORK/postgres.log" -w \
      -o "-p $PORT -k $WORK -c listen_addresses='' -c fsync=off -c wal_level=logical" start >/dev/null
  fi
}

stop_cluster() {
  if [ -z "${KEEP_CLUSTER:-}" ]; then
    "${RUN_AS[@]}" "$PGBIN/pg_ctl" -D "$DATA" -m fast stop >/dev/null 2>&1 || true
  fi
}

PSQL=(psql -h "$WORK" -p "$PORT" -U postgres -v ON_ERROR_STOP=1 -q -X)

apply() { # db file
  "${PSQL[@]}" -d "$1" -f "$2" >/dev/null 2> >(grep -v -E 'NOTICE|^$' >&2) || {
    echo "FAILED applying $2" >&2; exit 1; }
}

start_cluster
trap stop_cluster EXIT

overall=0
for country in "${COUNTRIES[@]}"; do
  db="iwant_${country}"
  echo "==> [$country] fresh database $db"
  "${PSQL[@]}" -d postgres -c "drop database if exists $db" -c "create database $db" >/dev/null

  apply "$db" "$HERE/shims.sql"
  for f in "$SUPA"/migrations/*.sql; do
    apply "$db" "$f"
  done
  echo "    migrations applied: $(ls "$SUPA"/migrations/*.sql | wc -l)"

  apply "$db" "$SUPA/seed.sql"
  apply "$db" "$SUPA/seed/$country.sql"
  if [ -z "${NO_DEMO:-}" ]; then
    apply "$db" "$SUPA/seed/demo_generator.sql"
    apply "$db" "$SUPA/seed/${country}_demo.sql"
  fi
  "${PSQL[@]}" -d "$db" -At -c "select format('    seeded: %s categories, %s postal codes, %s sellers, %s requests, %s quotes, %s orders',
      (select count(*) from categories), (select count(*) from postal_codes), (select count(*) from sellers),
      (select count(*) from requests), (select count(*) from quotes), (select count(*) from orders))"

  echo "==> [$country] pgTAP"
  if ! pg_prove -h "$WORK" -p "$PORT" -U postgres -d "$db" --ext .sql -r "$SUPA/tests/database"; then
    overall=1
  fi
done
exit $overall
