#!/bin/bash

# Here, we'll install Kubernetes

# Adjust kubeadm verbosity if needed
#KUBEADM_VERBOSITY=
#KUBEADM_VERBOSITY="-v 5"
KUBEADM_VERBOSITY="-v 4"

# Kubelet requires swap off (after reboot):
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Install Kubernetes from the Google packages
sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

# kubeadm pacage will drag its dependencies like kubelet
echo "Install kubeadm"
sudo apt-get update
sudo apt-get install -y kubeadm

# Note that even though we'll have to configure kubelet so that it uses the systemd cgroup driver, this can no longer work, as the roup-driver option has been deprecated
# We'll do it some other way later on
#echo "Configure cgroup driver for kubelet"
#cat <<EOF |  sudo tee /etc/default/kubelet
#KUBELET_EXTRA_ARGS=--cgroup-driver=systemd 
#EOF
#sudo systemctl daemon-reload
#sudo systemctl restart kubelet

echo "Create cluster"

# We're going to setup the cluster config through a YAML manifest
# passed to kubeadm, since some options are no longer available as
# arguments to the command (for kubelet's cgroups driver mainly)

# First interface with default route set to it
INTERFACE=$(sudo /sbin/route | grep '^default' | grep -o '[^ ]*$' | head -n 1)
IPADDR=`sudo ifconfig $INTERFACE | grep -i mask | awk '{print $2}'| cut -f2 -d:`
NODENAME=$(hostname -s)

# This was the way we did it before
#sudo kubeadm init --apiserver-cert-extra-sans=$IPADDR  --node-name $NODENAME --cri-socket=/run/containerd/containerd.sock --pod-network-cidr=192.168.0.0/16

# The --cgroup-driver=systemd kubelet option being deprecated, we use the KubeletConfiguration config item to set it
# but this forces us to get rid of other kubeadm options, which end up in the same config file
# TODO: backup olf file if already there
# Adjust the POD network (podSubnet) if need be
cat <<EOF | sudo tee /root/kubeadmin-config.yaml
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
apiServer:
  certSANs:
  - "IPADDR"
networking:
  podSubnet: "192.168.0.0/16"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: "systemd"
---
apiVersion: kubeadm.k8s.io/v1beta1
kind: InitConfiguration
nodeRegistration:
  criSocket: "unix:///run/containerd/containerd.sock"

EOF
sudo sed -i "s/IPADDR/$IPADDR/g" /root/kubeadmin-config.yaml

# At long last, start installing the cluster
#sudo kubeadm init -v 5 --config /root/kubeadmin-config.yaml --cri-socket /run/containerd/containerd.sock --node-name $NODENAME
sudo kubeadm init $KUBEADM_VERBOSITY --config /root/kubeadmin-config.yaml --node-name $NODENAME

# Once the cluster is installed, copy admin credentials to vagrant
# user, so that kubectl can be used directly after vagrant ssh
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown -R $USER:$USER $HOME/.kube

# Wait a minute for everything to start (VirtualBox is slow ?)
sleep 60

# remove master role taint (1 node cluster)
kubectl taint nodes --all node-role.kubernetes.io/master-

# Wait for components to be activated
kubectl wait --timeout=300s --for=condition=Ready -n kube-system pod -l k8s-app=kube-proxy
sleep 60
kubectl wait --timeout=300s --for=condition=Ready -n kube-system pod -l component=etcd
