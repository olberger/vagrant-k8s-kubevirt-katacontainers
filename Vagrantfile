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

#No longer supported
# Minikube Variables
#KUBERNETES_VERSION = ENV['KUBERNETES_VERSION'] || "1.14.0"


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

  # Image is 64 Gb
  vmCfg.vm.box = "generic/ubuntu1804"
  
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
  vmCfg.vm.provision "shell", path: "crio.sh", privileged: false 
  vmCfg.vm.provision "shell", path: "kubernetes.sh", privileged: false 
  vmCfg.vm.provision "shell", path: "kubevirt.sh", privileged: false
  vmCfg.vm.provision "shell", path: "rancher-local-path-provisioner.sh", privileged: false
  vmCfg.vm.provision "shell", path: "cdi.sh", privileged: false
  vmCfg.vm.provision "shell", path: "kata.sh", privileged: false 
  vmCfg.vm.provision "shell", path: "demo.sh", privileged: false 
  return vmCfg
end

# Entry point of this Vagrantfile
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vbguest.auto_update = false

  1.upto(NODES.to_i) do |i|
    hostname = "kubernetes-vagrant-%02d" % [i]
    cpus = CPUS
    mem = MEM
    srcdir = SRCDIR
    dstdir = DSTDIR
    
    config.vm.define hostname do |vmCfg|
      vmCfg = configureVM(vmCfg, hostname, cpus, mem, srcdir, dstdir)  
    end
  end

end
