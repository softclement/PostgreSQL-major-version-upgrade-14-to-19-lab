#!/usr/bin/env bash
# Dry run or real upgrade of pg14 -> PostgreSQL 19.  Usage: scripts/upgrade.sh check | upgrade
set -euo pipefail
MODE="${1:?usage: upgrade.sh check|upgrade}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TGT=pg19-from14; VOL_NEW=pgdata19_from14
IMG_NEW=docker.io/library/postgres:19rc1

podman stop pg14 >/dev/null 2>&1 || true        # old cluster must be cleanly shut down
# always bring the old cluster back when this script ends (its data is only copied, never changed)
trap 'podman start pg14 >/dev/null 2>&1; until podman exec pg14 pg_isready -q -h 127.0.0.1 -U postgres 2>/dev/null; do sleep 1; done' EXIT

# new empty cluster via the official entrypoint; PG18+ initdb enables checksums, old cluster has them off
if ! podman volume exists "$VOL_NEW"; then
  podman volume create "$VOL_NEW" >/dev/null
  podman run -d --name "$TGT" -e POSTGRES_PASSWORD=postgres -e POSTGRES_INITDB_ARGS="--no-data-checksums" \
    -v "$VOL_NEW":/var/lib/postgresql -p 5114:5432 "$IMG_NEW" >/dev/null
  until podman exec "$TGT" pg_isready -q -h 127.0.0.1 -U postgres; do sleep 1; done
  podman exec "$TGT" psql -U postgres -Atc "show data_directory" > "$HERE/out/newdata.txt"
  podman stop "$TGT" >/dev/null
fi
NEWDATA="$(cat "$HERE/out/newdata.txt")"; echo "new data dir: $NEWDATA"

podman run --rm --user root -e NEWDATA="$NEWDATA" -e MODE="$MODE" \
  -v pgdata14:/old/data -v "$VOL_NEW":/var/lib/postgresql -v "$HERE/scripts":/scripts:ro \
  "$IMG_NEW" bash /scripts/in_upgrader.sh
