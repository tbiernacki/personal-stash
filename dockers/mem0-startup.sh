#!/bin/sh
set -e

# Install OS dependencies
apt-get update
apt-get install -y openssh-server curl
mkdir -p /var/run/sshd

# Setup root SSH (adjust for production!)
echo "root:secret" | chpasswd
ssh-keygen -A
/usr/sbin/sshd

# Install Python dependencies
pip install --no-cache-dir mem0ai qdrant-client uvicorn[standard]

# Ensure working folder exists and data is saved there
mkdir -p /root/mem0

# Launch Mem0 FastAPI
uvicorn mem0.server.main:app --host 0.0.0.0 --port 8000
