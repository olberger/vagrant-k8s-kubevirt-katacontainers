#!/bin/bash

# We're making sure containerd is installed and configured properly, to use the CRI plugin

# source: https://kubernetes.io/docs/setup/cri/#docker

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat  <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

# Install containerd

# Some of these steps are already done for installation of Docker CE, but that doesn't harm repeating.

## Set up the repository
### Install packages to allow apt to use a repository over HTTPS
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

### Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

### Add Docker apt repository.
sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

## Install containerd
sudo apt-get update && sudo apt-get install -y containerd.io

# Now the novel parts : configuration

# Configure containerd
sudo mkdir -p /etc/containerd

# Some docs instruct to dump all parameters there, but that seems
# counterproductive. We'll just specify what is non-standard.  sudo
#containerd config default | sudo tee /etc/containerd/config.toml
# sudo sed -i 's/systemd_cgroup = false/systemd_cgroup = true/g' /etc/containerd/config.toml
# TODO: backup olf file if already there
# Specify the systemd cgroups driver here too
cat  <<EOF | sudo tee /etc/containerd/config.toml
[debug]
  level = "info"
[plugins]
  [plugins.cri]
    systemd_cgroup = true
EOF

# Restart containerd
sudo systemctl restart containerd

# Install crictl
VERSION="v1.14.0"
wget -q https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
sudo tar zxf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$VERSION-linux-amd64.tar.gz

# This should then work
# crictl -r unix:///run/containerd/containerd.sock info

# Let's make the containerd CRI runtime the defaut
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
EOF

# This should work, then:
# crictl info
