#!/bin/bash
sudo apt-get update

# Install Docker in Ubuntu
# Add Docker's official GPG key:
sudo apt install apt-transport-https ca-certificates curl software-properties-common -Y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce -Y

# Install Docker Compose
sudo apt install docker-compose -Y

# Clone the GitHub repository
sudo apt-get install -y git
cd /home/ubuntu
git clone https://github.com/tvieirabruna/app-voting-observability.git

# Navigate to the Prometheus folder
cd app-voting-observability/metrics/prometheus

# Run Docker
sudo docker-compose up -d