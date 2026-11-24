#!/usr/bin/env bash
# Installs NVIDIA Container Toolkit (official NVIDIA apt repo) and registers it with Docker.
set -euo pipefail

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor --yes -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

echo
echo "=== Done. Docker runtimes: ==="
docker info 2>/dev/null | grep -i runtimes
echo "NVIDIA_TOOLKIT_INSTALL_FINISHED"
