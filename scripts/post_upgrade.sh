#!/usr/bin/env bash
# Tasks after the upgrade: update extensions, refresh statistics, check collation versions.
set -euo pipefail
T=pg19-from14
podman start "$T" >/dev/null
until podman exec "$T" pg_isready -q -h 127.0.0.1 -U postgres; do sleep 1; done

echo "== 1. update extensions in every database =="
for db in $(podman exec "$T" psql -U postgres -Atc "select datname from pg_database where datallowconn"); do
  podman exec -i "$T" psql -U postgres -d "$db" -q <<'SQL'
SELECT format('ALTER EXTENSION %I UPDATE', name) FROM pg_available_extensions
WHERE installed_version IS NOT NULL AND installed_version <> default_version \gexec
SQL
done

echo "extension update: done"

echo "== 2. planner stats (only what is missing) =="
podman exec "$T" vacuumdb -U postgres --all --analyze-in-stages --missing-stats-only

echo "== 3. collation version check (mismatch => REINDEX) =="
podman exec "$T" psql -U postgres -d appdb \
  -c "select datname, datcollversion, pg_database_collation_actual_version(oid) as actual from pg_database where datallowconn" \
  -c "select collname, collversion, pg_collation_actual_version(oid) as actual from pg_collation where collnamespace = 'app'::regnamespace"
