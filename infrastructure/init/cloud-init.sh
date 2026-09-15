#!/usr/bin/env bash
# cloud-init setup script for DevSecOps Security POC Platform
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "=== [1/6] Updating System Packages ==="
apt-get update -y && apt-get upgrade -y

echo "=== [2/6] Installing Essential Tooling & Nginx ==="
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  git \
  jq \
  tar \
  nginx \
  ufw \
  net-tools

echo "=== [3/6] Installing Docker Engine & Docker Compose ==="
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker
systemctl enable --now docker
usermod -aG docker ubuntu || true

echo "=== [4/6] Installing .NET 8 SDK ==="
apt-get install -y dotnet-sdk-8.0 || {
  wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
  dpkg -i packages-microsoft-prod.deb
  rm packages-microsoft-prod.deb
  apt-get update -y
  apt-get install -y dotnet-sdk-8.0
}

echo "=== [5/6] Configuring Firewall (UFW) ==="
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "=== [6/6] Base Initialization Complete ==="
echo "System ready for repository clone and execution of ./infrastructure/bootstrap/bootstrap.sh"