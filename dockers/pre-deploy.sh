# pre-deploy – clone/pull Mem0 repo and build local images

set -euo pipefail
#                ^ exit on error, no unset vars, detect pipe errors

# ──────────────────────────────────────────────────────────────
# Trap ERR so we can report what went wrong before the script quits
# ──────────────────────────────────────────────────────────────
trap 'echo " ERROR in ${BASH_SOURCE[0]} on line ${LINENO}: \
command \`$BASH_COMMAND\` exited with code $?" >&2' ERR
# If you use functions/sub-shells, also inherit the trap:
shopt -s errtrace   # ensures ERR trap fires inside functions too
# ──────────────────────────────────────────────────────────────

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
