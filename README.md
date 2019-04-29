# Kubernetes with kubevirt and kata-containers, inside Vagrant (with libvirt/kvm)

Provide a consistent way to run kubernetes with kubevirt and
kata-containers, locally across different distro's, providing nested virtualization is supported..

Note, this installs Kubernetes from official packages on ubuntu 18.04.

Include configuration for :

# Details
- Ubuntu 18.04 base image : roboxes/ubuntu1604 (from https://roboxes.org/ ?)
- Kubernetes installed with kubeadm, with :
  - cri-o container runtime
  - kubelet, cri-o using systemd cgroups driver
  - calico CNI network
  - kubevirt for running full-fledged qemu VMs
  - kata-containers for running containers, sandboxed inside mini VMs
    (qemu too)

This is a reworked Vagrant configuration based on initial version at https://github.com/mintel/vagrant-minikube taking additions from https://gist.github.com/avthart/d050b13cad9e5a991cdeae2bf43c2ab3 and my own findings

## Demo

Here's a recording :
[![asciicast](https://asciinema.org/a/243325.png)](https://asciinema.org/a/14)

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
  kubectl apply -f https://raw.githubusercontent.com/kubevirt/demo/master/manifests/vm.yaml
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

## Kata-containers

You can also test, from inside the VM, the launch of containers inside
qemu sandboxing:
```
kubectl apply -f https://raw.githubusercontent.com/kata-containers/packaging/master/kata-deploy/examples/test-deploy-kata-qemu.yaml
```

Once the container is running, you can run a shell inside it:
```
kubectl exec -it $(kubectl get pod -l run=php-apache-kata-qemu -o wide | awk 'NR==2 {print $1}') bash
```

## Testing on real OS

The scripts may be used, in the same order, to deploy a cluster on an (non-virtualized)
Ubuntu 18.04 Server machine.

So far, only limitation found is related to AppArmor libvirt constraints preventing VMs to be
started by KubeVirt.

Immediate workaround can be disabling it (which may not be the best
idea, YMMV):
```
sudo ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmor.d/disable/usr.sbin.libvirtd
```
