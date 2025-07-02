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

# 3. Mem0 setup
pip install fastapi uvicorn mem0ai qdrant-client psycopg2
uvicorn webhook_receiver:app --host 0.0.0.0 --port 8010

# Tail logs or keep container alive)
tail -f /dev/null
