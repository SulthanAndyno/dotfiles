#!/usr/bin/env bash
# Lightweight Docker container status probe (zero work when daemon socket is absent).
set -u

if [ ! -S /var/run/docker.sock ]; then
    echo "DOCKER_OFF"
    exit 0
fi

OUT=$(timeout 2 docker ps -a --format '{{.ID}}|{{.Names}}|{{.Image}}|{{.State}}|{{.Status}}' 2>/dev/null) || {
    echo "DOCKER_OFF"
    exit 0
}

echo "DOCKER_ON"
[ -n "$OUT" ] && printf "%s\n" "$OUT"
