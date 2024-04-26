#!/bin/bash
sudo apt-get update

# Install Docker in Ubuntu
# Add Docker's official GPG key:
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker packages
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Install Docker Compose
sudo apt-get install docker-compose-plugin

# Upgrade and update packages
sudo apt-get upgrade
sudo apt-get update

# Clone the GitHub repository
sudo apt-get install -y git
cd /home/ubuntu
git clone https://github.com/tvieirabruna/app-voting-observability.git

# Navigate to the Prometheus folder
cd app-voting-observability/metrics/prometheus

# Run Docker
sudo docker compose up -d