# Kubernetes with kubevirt inside Vagrant (with libvirt/kvm)

Provide a consistent way to run kubernetes with kubevirt locally across different distro's, providing nested virtualization is supported..

Note, this installs Kubernetes from official packages on ubuntu 16.04.

Include configuration for :

# Details
- Ubuntu 16.04 base image : roboxes/ubuntu1604 (from https://roboxes.org/ ?)
- Kubernetes installed with kubeadm, with :
  - cri-o container runtime
  - kubelet, cri-o using systemd cgroups driver
  - calico CNI network
  - kubevirt

This is a reworked Vagrant configuration based on initial version at https://github.com/mintel/vagrant-minikube taking additions from https://gist.github.com/avthart/d050b13cad9e5a991cdeae2bf43c2ab3 and my own findings

## Install Pre-requisites

Ensure you have vagrant installed (should also support mac/windows), with libvirt/KVM virtualization driver

https://www.vagrantup.com/docs/installation/

### Arch
```
sudo pacman -S vagrant
```

### Ubuntu
```
sudo apt-get install vagrant
```

## Run it

Clone this repo then:

```
vagrant up --provider=libvirt
```

## SSH into the VM
```
vagrant ssh
```

## Check minikube is up and running

```
kubectl get nodes
```

## Access your code inside the VM

We automatically mount `/tmp/vagrant` into `/home/vagrant/data`.

For example, you may want to `git clone` some kubernetes manifests into `/tmp/vagrant` on your host-machine, then you can access them in the vagrant machine.

This is bi-directional, and achieved via [vagrant-sshfs](https://github.com/dustymabe/vagrant-sshfs)

## Testing kubevirt qemu VM images inside Kubernetes cluster

First vagrant ssh inside the VM, then: 

- Declare a Kubevirt virtual machine to be started with qemu/kvm:
  ```
  vagrant$ kubectl apply -f https://raw.githubusercontent.com/kubevirt/demo/master/manifests/vm.yaml
  ...
  kubectl get vms
  ```

- Start the VM's execution (takes a while: downloading VM image, etc.)
  ```
  virtctl start testvm
  
  # wait until the VM is started
  kubectl wait --timeout=180s --for=condition=Ready pod -l kubevirt.io/domain=testvm
  # you can check the execution of qemu
  ps aux | grep qemu-system-x86_64
  ```

- Connect to the VM's console
  ```
  virtctl console testvm
  ```

