#!/bin/bash

# adapted from: https://www.avthart.com/posts/create-your-own-minikube-using-vagrant-and-kubeadm/ / https://gist.github.com/avthart/d050b13cad9e5a991cdeae2bf43c2ab3

# Kubelet requires swap off (after reboot):
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Install Kubernetes
echo "Install docker"
sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y docker.io 

echo "Configure cgroups driver via systemd"
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

# Restart docker.
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "Install kubeadm"
sudo apt-get install -y kubeadm

# Force use of systemd driver for cgroups since kubelet will use cri-o
echo "Configure cgroup driver for kubelet"
cat <<EOF |  sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS=--cgroup-driver=systemd 
EOF
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Add docker.io registry of images
echo "Configure container registries to include docker.io"
#sudo sed -i 's/#registries = \[/registries = \["docker.io"\]/g' /etc/crio/crio.conf
cat <<EOF |  sudo tee /etc/containers/registries.conf
# This is a system-wide configuration file used to
# keep track of registries for various container backends.
# It adheres to TOML format and does not support recursive
# lists of registries.

# The default location for this configuration file is /etc/containers/registries.conf.

# The only valid categories are: 'registries.search', 'registries.insecure', 
# and 'registries.block'.

[registries.search]
registries = ['docker.io']

# If you need to access insecure registries, add the registry's fully-qualified name.
# An insecure registry is one that does not have a valid SSL certificate or only does HTTP.
[registries.insecure]
registries = []


# If you need to block pull access from a registry, uncomment the section below
# and add the registries fully-qualified name.
#
# Docker only
[registries.block]
registries = []
EOF
sudo systemctl daemon-reload
sudo systemctl restart crio

echo "Pulling container images for Kubernetes"
sudo kubeadm config images pull --cri-socket=/var/run/crio/crio.sock

echo "Create cluster"
# Install using kubeadm 
IPADDR=`sudo ifconfig eth0 | grep Mask | awk '{print $2}'| cut -f2 -d:`
NODENAME=$(hostname -s)
sudo kubeadm init --apiserver-cert-extra-sans=$IPADDR  --node-name $NODENAME --cri-socket=/var/run/crio/crio.sock --pod-network-cidr=192.168.0.0/16


# Copy admin credentials to vagrant user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $USER:$USER $HOME/.kube/config

# remove master role taint
kubectl taint nodes --all node-role.kubernetes.io/master-

echo "Deploy calico network"
# deploy calico network
kubectl apply -f https://docs.projectcalico.org/v3.6/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml

# wait until calico is stated
echo "wait for 30s before checking if calico is started"
sleep 30

echo "wait for calico to be started"
kubectl wait --timeout=180s --for=condition=Ready -n kube-system pod -l k8s-app=calico-kube-controllers
kubectl wait --timeout=180s --for=condition=Ready -n kube-system pod -l k8s-app=calico-node

# get componentstats
kubectl get componentstatus
