#!/bin/sh
set -e

apt-get update
apt-get install -y openssh-server curl
mkdir -p /var/run/sshd

echo "root:secret" | chpasswd
ssh-keygen -A
/usr/sbin/sshd

pip install --no-cache-dir mem0ai qdrant-client uvicorn[standard]

# Start the official Mem0 REST API server
mem0-server --host 0.0.0.0 --port 8000
