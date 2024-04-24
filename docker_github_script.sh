#!/bin/bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo snap install docker
sudo systemctl start docker
sudo systemctl enable docker

# Clone the GitHub repository
sudo apt-get install -y git
cd /home/ubuntu
git clone https://github.com/tvieirabruna/app-voting-observability.git

# Navigate to the Prometheus folder
cd app-voting-observability/metrics/prometheus

# Run Docker
sudo docker-compose up -d