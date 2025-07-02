#!/bin/sh
set -e

# 1. Install OS deps
apt-get update
apt-get install -y openssh-server curl git gcc g++ libffi-dev libpq-dev libssl-dev make

# 2. SSH setup
mkdir -p /var/run/sshd
echo "root:secret" | chpasswd
ssh-keygen -A
/usr/sbin/sshd

# 3. Clone mem0 repo if not exists
cd /root/mem0
if [ ! -d mem0 ]; then
  git clone https://github.com/mem0ai/mem0.git repo
fi

# 4. Install Python requirements for server & openmemory
cd /root/mem0/repo/server
pip install --upgrade pip
pip install -r requirements.txt

cd /root/mem0/openmemory
pip install -r requirements.txt

# 5. Now install mem0 core SDK and qdrant-client
pip install mem0ai qdrant-client

# 6. Start both servers in background
# MCP UI/API (OpenMemory)
cd /root/mem0/repo/openmemory
uvicorn main:app --host 0.0.0.0 --port 8000 &

# Mem0 API server
cd /root/mem0/repo/server
uvicorn main:app --host 0.0.0.0 --port 8001

# (Optional: Tail logs or keep container alive)
tail -f /dev/null
