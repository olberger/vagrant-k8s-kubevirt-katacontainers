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

# Common installation script
$installer = <<SCRIPT
#!/bin/bash

# Update apt and get dependencies
sudo apt-get -y update
sudo apt-mark hold grub 
sudo apt-mark hold grub-pc
sudo apt-get -y upgrade
sudo apt-get install -y zip unzip curl wget socat ebtables git vim 

SCRIPT

$dockerold = <<SCRIPT
#!/bin/bash

#curl -fsSL https://apt.dockerproject.org/gpg | sudo apt-key add -
#sudo apt-add-repository "deb https://apt.dockerproject.org/repo ubuntu-xenial main"
#sudo apt-get install -y docker-engine=17.03.1~ce-0~ubuntu-xenial

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get -y update
sudo apt-get install -y docker-ce=17.03.3~ce-0~ubuntu-$(lsb_release -cs)
sudo systemctl start docker

sudo usermod -a -G docker vagrant

SCRIPT

$docker = <<SCRIPT
#!/bin/bash

# source: https://kubernetes.io/docs/setup/cri/#docker

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
sudo apt-get update && sudo apt-get install -y docker-ce=18.06.2~ce~3-0~ubuntu

# Setup daemon.
cat <<EOF > /tmp/docker-daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sudo mv /tmp/docker-daemon.json /etc/docker/daemon.json

sudo mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
sudo systemctl daemon-reload
sudo systemctl restart docker


sudo usermod -a -G docker vagrant

SCRIPT

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

$minikubescript = <<SCRIPT
#!/bin/bash

#Install minikube
echo "Downloading Minikube"
curl -q -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 2>/dev/null
chmod +x minikube 
sudo mv minikube /usr/local/bin/

#Install kubectl
echo "Downloading Kubectl"
curl -q -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubectl 2>/dev/null
chmod +x kubectl 
sudo mv kubectl /usr/local/bin/

# Install crictl
curl -qL https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.12.0/crictl-v1.12.0-linux-amd64.tar.gz 2>/dev/null | tar xzvf -
chmod +x crictl
sudo mv crictl /usr/local/bin/

#Install stern
# TODO: Check sha256sum
echo "Downloading Stern"
curl -q -Lo stern https://github.com/wercker/stern/releases/download/1.10.0/stern_linux_amd64 2>/dev/null                                                                                 
chmod +x stern
sudo mv stern /usr/local/bin/

#Install kubecfg
# TODO: Check sha256sum
echo "Downloading Kubecfg"
curl -q -Lo kubecfg https://github.com/ksonnet/kubecfg/releases/download/v0.9.0/kubecfg-linux-amd64 2>/dev/null                                                      
chmod +x kubecfg
sudo mv kubecfg /usr/local/bin/

#Setup minikube
echo "127.0.0.1 minikube minikube." | sudo tee -a /etc/hosts
mkdir -p $HOME/.minikube
mkdir -p $HOME/.kube
touch $HOME/.kube/config

export KUBECONFIG=$HOME/.kube/config

# Permissions
sudo chown -R $USER:$USER $HOME/.kube
sudo chown -R $USER:$USER $HOME/.minikube

export MINIKUBE_WANTUPDATENOTIFICATION=false
export MINIKUBE_WANTREPORTERRORPROMPT=false
export MINIKUBE_HOME=$HOME
export CHANGE_MINIKUBE_NONE_USER=true
export KUBECONFIG=$HOME/.kube/config

# Disable SWAP since is not supported on a kubernetes cluster
sudo swapoff -a

# ## Start minikube 
sudo -E minikube start -v 4 --vm-driver none --kubernetes-version v${KUBERNETES_VERSION} --container-runtime=cri-o --bootstrapper kubeadm 
# sudo -E minikube start -v 4 --vm-driver none --kubernetes-version v${KUBERNETES_VERSION} --container-runtime=cri-o

# ## Addons 
# sudo -E minikube addons  enable ingress

# ## Configure vagrant clients dir

# printf "export MINIKUBE_WANTUPDATENOTIFICATION=false\n" >> /home/vagrant/.bashrc
# printf "export MINIKUBE_WANTREPORTERRORPROMPT=false\n" >> /home/vagrant/.bashrc
# printf "export MINIKUBE_HOME=/home/vagrant\n" >> /home/vagrant/.bashrc
# printf "export CHANGE_MINIKUBE_NONE_USER=true\n" >> /home/vagrant/.bashrc
# printf "export KUBECONFIG=/home/vagrant/.kube/config\n" >> /home/vagrant/.bashrc
# printf "source <(kubectl completion bash)\n" >> /home/vagrant/.bashrc

# # Permissions
# sudo chown -R $USER:$USER $HOME/.kube
# sudo chown -R $USER:$USER $HOME/.minikube

# # Enforce sysctl 
# sudo sysctl -w vm.max_map_count=262144
# sudo echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.d/90-vm_max_map_count.conf

SCRIPT

# source: https://www.avthart.com/posts/create-your-own-minikube-using-vagrant-and-kubeadm/ / https://gist.github.com/avthart/d050b13cad9e5a991cdeae2bf43c2ab3
$kubernetes = <<-SCRIPT
# Kubelet requires swap off (after reboot):
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Install Kubernetes
sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
#sudo apt-get install -y docker.io kubeadm kubectl
sudo apt-get install -y docker.io 

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

# Make sure kubelet will use the same cgroup driver as Docker:
# cat <<EOF | sudo tee /etc/default/kubelet
# KUBELET_EXTRA_ARGS=--cgroup-driver=systemd 
# EOF
# sudo systemctl daemon-reload
# sudo systemctl restart kubelet

sudo apt-get install -y kubeadm

sudo kubeadm config images pull

# # Install using kubeadm 
IPADDR=`sudo ifconfig eth0 | grep Mask | awk '{print $2}'| cut -f2 -d:`
NODENAME=$(hostname -s)
sudo kubeadm init --apiserver-cert-extra-sans=$IPADDR  --node-name $NODENAME --pod-network-cidr=10.244.0.0/16
#sudo kubeadm init

# Copy admin credentials to vagrant user
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config

# # remove master role taint
# kubectl taint nodes --all node-role.kubernetes.io/master-

# # deploy calico network
# kubectl apply -f \
# https://docs.projectcalico.org/v3.4/getting-started/kubernetes/installation/hosted/etcd.yaml
# kubectl apply -f \ https://docs.projectcalico.org/v3.4/getting-started/kubernetes/installation/hosted/calico.yaml

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml

# # get componentstats
kubectl get componentstatus

# # get all resources
kubectl get all --all-namespaces
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

  # ensure docker is installed # Use our script so we can get a proper support version
#  vmCfg.vm.provision "shell", inline: $docker, privileged: false 
  # Script to prepare the VM
#  vmCfg.vm.provision "shell", inline: $installer, privileged: false 
  vmCfg.vm.provision "shell", inline: $growpart, privileged: false if GROWPART == "true"
#  vmCfg.vm.provision "shell", inline: $crio, privileged: false 
#  vmCfg.vm.provision "shell", inline: $minikubescript, privileged: false, env: {"KUBERNETES_VERSION" => KUBERNETES_VERSION}
  vmCfg.vm.provision "shell", inline: $kubernetes, privileged: false 

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
