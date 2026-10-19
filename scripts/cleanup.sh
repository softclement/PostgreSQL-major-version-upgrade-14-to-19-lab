#!/usr/bin/env bash
# usage: cleanup.sh            -> remove the lab containers and volumes
#        cleanup.sh --images   -> also remove the PostgreSQL images used by this lab
podman rm -f -v pg14 pg19 pg19-from14 2>/dev/null || true
podman volume rm -f pgdata14 pgdata19_from14 2>/dev/null || true
if [ "${1:-}" = "--images" ]; then
  podman rmi -f docker.io/library/postgres:14 docker.io/library/postgres:19rc1 2>/dev/null || true
  podman rmi -f localhost/pg-upgrader:19rc1 localhost/pg-upgrader:19beta3 2>/dev/null || true   # only exist if you built them earlier
fi
echo "--- containers left ---";  podman ps -a --format '{{.Names}}'
echo "--- volumes left ---";     podman volume ls --format '{{.Name}}'
echo "--- images left ---";      podman images --format '{{.Repository}}:{{.Tag}}'
