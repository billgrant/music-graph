#!/bin/bash
set -e  # Exit on error

# Update system
sudo apt-get update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Wait for Docker to be ready
until docker info >/dev/null 2>&1; do
  echo "Waiting for Docker..."
  sleep 1
done

# Add user to docker group
usermod -aG docker ${SSH_USER:-ubuntu}

# Install Docker Compose
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version

# Install git
sudo apt-get install -y git

echo "Setup complete at $(date)" >> /home/${SSH_USER:-ubuntu}/setup.log