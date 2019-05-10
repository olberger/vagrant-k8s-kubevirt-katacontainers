#!/bin/bash

# We're installing Docker CE from Docker.com which seem to be working well with containerd and the cri plugin

# Main source: https://kubernetes.io/docs/setup/cri/#docker

# Install Docker CE
## Set up the repository:
### Install packages to allow apt to use a repository over HTTPS
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

### Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

### Add Docker apt repository.
sudo add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

## Install Docker CE.
#sudo apt-get update && sudo apt-get install docker-ce=18.06.2~ce~3-0~ubuntu
sudo apt-get update && sudo apt-get install -y docker-ce

# Setup daemon to use the systemd cgroup driver
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
sudo systemctl daemon-reload
sudo systemctl restart docker
