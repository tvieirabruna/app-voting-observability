#!/bin/bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Clone the GitHub repository
sudo apt-get install -y git
cd /home/ubuntu
git clone https://github.com/tvieirabruna/app-voting-observability.git