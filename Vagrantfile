# coding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">= 2.0.0"

# just a single node is required
NODES = ENV['NODES'] || 1

# Memory & CPUs
MEM = ENV['MEM'] || 6144
CPUS = ENV['CPUS'] || 2

# User Data Mount
#SRCDIR = ENV['SRCDIR'] || "/home/"+ENV['USER']+"/test"
SRCDIR = ENV['SRCDIR'] || "/tmp/vagrant"
DSTDIR = ENV['DSTDIR'] || "/home/vagrant/data"

# Management 
GROWPART = ENV['GROWPART'] || "true"

# Minikube Variables
KUBERNETES_VERSION = ENV['KUBERNETES_VERSION'] || "1.14.0"


$growpart = <<SCRIPT
#!/bin/bash

if [[ -b /dev/vda3 ]]; then
  sudo growpart /dev/vda 3
  sudo resize2fs /dev/vda3
elif [[ -b /dev/sda3 ]]; then
  sudo growpart /dev/sda 3
  sudo resize2fs /dev/sda3
fi

SCRIPT

$crio = <<SCRIPT
#!/bin/bash

# source: https://kubernetes.io/docs/setup/cri/#prerequisites

modprobe overlay
modprobe br_netfilter

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
sudo apt-get install -y cri-o-1.12

sudo systemctl start crio

#sudo apt-get install -y podman

SCRIPT

# adapted from: https://www.avthart.com/posts/create-your-own-minikube-using-vagrant-and-kubeadm/ / https://gist.github.com/avthart/d050b13cad9e5a991cdeae2bf43c2ab3
$kubernetes = <<-SCRIPT
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
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config

# remove master role taint
kubectl taint nodes --all node-role.kubernetes.io/master-

echo "Deploy calico network"
# deploy calico network
kubectl apply -f https://docs.projectcalico.org/v3.6/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml

# wait until calico is stated
echo "wait for calico to be started"
kubectl wait --timeout=180s --for=condition=Ready -n kube-system pod -l k8s-app=calico-kube-controllers

# get componentstats
kubectl get componentstatus

# get all resources
#kubectl get all --all-namespaces
SCRIPT

$kubevirt = <<-SCRIPT
echo "Deploy kubevirt"
export KUBEVIRT_RELEASE=v0.15.0
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/$KUBEVIRT_RELEASE/kubevirt-operator.yaml
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/$KUBEVIRT_RELEASE/kubevirt-cr.yaml

curl -q -Lo virtctl \
    https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_RELEASE}/virtctl-${KUBEVIRT_RELEASE}-linux-amd64
chmod +x virtctl
sudo mv virtctl /usr/local/bin/
SCRIPT

required_plugins = %w(vagrant-sshfs vagrant-vbguest vagrant-libvirt)

required_plugins.each do |plugin|
  need_restart = false
  unless Vagrant.has_plugin? plugin
    system "vagrant plugin install #{plugin}"
    need_restart = true
  end
  exec "vagrant #{ARGV.join(' ')}" if need_restart
end


def configureVM(vmCfg, hostname, cpus, mem, srcdir, dstdir)

  vmCfg.vm.box = "roboxes/ubuntu1604"
  
  vmCfg.vm.hostname = hostname
  vmCfg.vm.network "private_network", type: "dhcp",  :model_type => "virtio", :autostart => true

  vmCfg.vm.synced_folder '.', '/vagrant', disabled: true
  # sync your laptop's development with this Vagrant VM
  vmCfg.vm.synced_folder srcdir, dstdir, type: "rsync", rsync__exclude: ".git/", create: true

  # First Provider - Libvirt
  vmCfg.vm.provider "libvirt" do |provider, override|
    provider.memory = mem
    provider.cpus = cpus
    provider.driver = "kvm"
    provider.disk_bus = "scsi"
    provider.machine_virtual_size = 64
    provider.video_vram = 64

 
    override.vm.synced_folder srcdir, dstdir, type: 'sshfs', ssh_opts_append: "-o Compression=yes", sshfs_opts_append: "-o cache=no", disabled: false, create: true
  end
  
  vmCfg.vm.provider "virtualbox" do |provider, override|
    provider.memory = mem
    provider.cpus = cpus
    provider.customize ["modifyvm", :id, "--cableconnected1", "on"]

    override.vm.synced_folder srcdir, dstdir, type: 'virtualbox', create: true
  end

  # Script to prepare the VM
  vmCfg.vm.provision "shell", inline: $growpart, privileged: false if GROWPART == "true"
  vmCfg.vm.provision "shell", inline: $crio, privileged: false 
  vmCfg.vm.provision "shell", inline: $kubernetes, privileged: false 
  vmCfg.vm.provision "shell", inline: $kubevirt, privileged: false 
  return vmCfg
end

# Entry point of this Vagrantfile
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vbguest.auto_update = false

  1.upto(NODES.to_i) do |i|
    hostname = "minikube-vagrant-%02d" % [i]
    cpus = CPUS
    mem = MEM
    srcdir = SRCDIR
    dstdir = DSTDIR
    
    config.vm.define hostname do |vmCfg|
      vmCfg = configureVM(vmCfg, hostname, cpus, mem, srcdir, dstdir)  
    end
  end

end
