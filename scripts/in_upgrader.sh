#!/usr/bin/env bash
# Runs INSIDE a temporary postgres:19rc1 container (started by upgrade.sh). Installs PG14 programs, then runs pg_upgrade.
set -euo pipefail
: "${NEWDATA:?}" "${MODE:?}"
# step 1 (root): install the PG14 binaries next to the PG19 ones, then drop to user postgres
if [ "$(id -u)" = 0 ]; then
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends postgresql-14 >/dev/null
  exec gosu postgres bash "$0"
fi
# step 2 (postgres): run pg_upgrade
OLDBIN=/usr/lib/postgresql/14/bin
NEWBIN="$(dirname "$(command -v pg_upgrade)")"
mkdir -p /var/lib/postgresql/work && cd /var/lib/postgresql/work
echo "== old =="; "$OLDBIN/pg_controldata" /old/data | grep -E "cluster state|checksum version"
echo "== new =="; "$NEWBIN/pg_controldata" "$NEWDATA" | grep -E "cluster state|checksum version"
ARGS=(-b "$OLDBIN" -B "$NEWBIN" -d /old/data -D "$NEWDATA" --jobs=2)
if [ "$MODE" = check ]; then ARGS+=(--check); fi
set +e
time "$NEWBIN/pg_upgrade" "${ARGS[@]}"
rc=$?
set -e
if [ "$rc" -ne 0 ]; then
  echo
  echo "== details from the pg_upgrade report files =="
  for f in "$NEWDATA"/pg_upgrade_output.d/*/*.txt; do
    [ -f "$f" ] && { echo "--- $(basename "$f")"; cat "$f"; }
  done
  exit "$rc"
fi
