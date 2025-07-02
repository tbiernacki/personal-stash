#!/usr/bin/env sh
# pre-deploy – clone/pull Mem0 repo and build local images

# Fail fast on any error or unset var.
set -eu
# BusyBox dash doesn’t know -o pipefail; guard with 2>/dev/null
(set -o pipefail) 2>/dev/null || true

#── Minimal, POSIX-safe ERR trap
#   $LINENO is POSIX; $0 is script name.  We can’t print $BASH_COMMAND,
#   but we still get line number & exit code.
trap 'ec=$?; printf "❌  ERROR in %s at line %s (exit %s)\n" "$0" "$LINENO" "$ec" >&2' ERR
#----------------------------------------------------------------------------

CODE_DIR="/home/brovar/Docker/mem0/src"
REPO="https://github.com/mem0ai/mem0.git"

 # Get init scripts for the Linux container
 wget -O mem0-init.sh https://raw.githubusercontent.com/tbiernacki/personal-stash/refs/heads/main/dockers/mem0-init.sh
 wget -O webhook_receiver.py https://raw.githubusercontent.com/tbiernacki/personal-stash/refs/heads/main/dockers/webhook_receiver.py
 chmod +x mem0-init.sh
 chmod +x webhook_receiver.py

echo " Syncing Mem0 repo…"
if [ -d "/home/brovar/Docker/mem0/src/.git" ]; then
    git -C "/home/brovar/Docker/mem0/src" fetch --depth 1 origin main
    git -C "/home/brovar/Docker/mem0/src" reset --hard origin/main
else
    git clone --depth 1 "$REPO" "$CODE_DIR"
fi

echo " Ensuring buildx is ready…"
docker buildx inspect default >/dev/null 2>&1 || docker buildx create --name mem0bx --use

echo " Building mem0_api_local (AMD64)…"
docker buildx build \
  --platform linux/amd64 \
  --load \
  -t mem0_api_local:latest \
  "$CODE_DIR/server"

echo " Building openmemory_local (AMD64)…"
docker buildx build \
  --platform linux/amd64 \
  --load \
  -t openmemory_local:latest \
  "$CODE_DIR/openmemory"

echo " pre-deploy completed successfully."
