#!/bin/sh
set -e
apt-get update && apt-get install -y openssh-server curl python3 python3-pip
mkdir -p /var/run/sshd
echo "root:secret" | chpasswd
ssh-keygen -A
/usr/sbin/sshd

pip install mem0ai qdrant-client uvicorn

# Run core FastAPI app
python3 -m mem0.server.main --host 0.0.0.0 --port 8000
