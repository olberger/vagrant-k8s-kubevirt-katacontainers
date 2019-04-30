#!/bin/bash

# source: https://kubernetes.io/docs/setup/cri/#prerequisites

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat > /tmp/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo mv /tmp/99-kubernetes-cri.conf /etc/sysctl.d/99-kubernetes-cri.conf
sudo sysctl --system


# Install prerequisites
sudo apt-get update && sudo apt-get install -y software-properties-common

sudo add-apt-repository -y ppa:projectatomic/ppa && sudo apt-get update

# Install CRI-O
#sudo apt-get install -y cri-o-1.11
#sudo apt-get install -y cri-o-1.12
sudo apt-get install -y cri-o-1.13

sudo systemctl start crio

#sudo apt-get install -y podman

