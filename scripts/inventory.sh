#!/usr/bin/env bash
# Take a snapshot of appdb (object counts + data fingerprints).  Usage: scripts/inventory.sh <container> <label>
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
podman exec -i "${1:?container}" psql -U postgres -d appdb -AtF ' | ' -q < "$HERE/sql/inventory.sql" > "$HERE/out/inv_${2:?label}.txt"
echo "wrote out/inv_$2.txt"
