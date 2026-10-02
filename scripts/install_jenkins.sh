#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: install_jenkins.sh
# Purpose: Automated bootstrap script for Ubuntu EC2 instances.
# Installs Java 21 LTS, Jenkins LTS, Git, and Docker Engine.
# Adds Jenkins service user to the Docker group for containerized builds.
# ==============================================================================

echo ">>> [1/6] Updating System Packages..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg fontconfig openjdk-21-jre git

echo ">>> [2/6] Adding Jenkins Official Repository Key & Source..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo 'deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/' | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

echo ">>> [3/6] Installing Jenkins..."
sudo apt-get update -y
sudo apt-get install -y jenkins

echo ">>> [4/6] Installing Docker Engine..."
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

echo ">>> [5/6] Granting Jenkins Permissions to Docker Socket..."
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu

echo ">>> [6/6] Starting & Enabling Jenkins Service..."
sudo systemctl enable jenkins
sudo systemctl restart jenkins

echo "=============================================================================="
echo ">>> Installation Complete! Jenkins Initial Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword || true
echo "=============================================================================="
