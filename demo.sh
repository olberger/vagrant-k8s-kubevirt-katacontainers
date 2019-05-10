#!/bin/bash

# Give instructions for testing the cluster

echo "."
echo "Log in inside the VM with 'vagrant ssh' and do some tests"
echo "."
echo "Test kata-containers with :"
echo "- start deployment of a test app:"
echo "  kubectl apply -f https://raw.githubusercontent.com/olberger/vagrant-kata-containerd/master/nginx-untrusted.yaml
echo "- wait until it's deployed:"
echo "  kubectl wait --timeout=180s --for=condition=Ready pod nginx-untrusted"
echo "- execute 'uname -a' inside the VM:"
echo '  kubectl exec -it nginx-untrusted uname -- -a'
echo "."
echo "."
echo "Test kubevirt with :"
echo "- declare a VM:"
echo "  kubectl apply -f https://raw.githubusercontent.com/kubevirt/demo/master/manifests/vm.yaml"
echo "  kubectl get vms"
echo "- start the VM:"
echo "  virtctl start testvm"
echo "- wait until it's deployed:"
echo "  kubectl wait --timeout=180s --for=condition=Ready pod -l kubevirt.io/domain=testvm"
echo "  kubectl get vmi"
echo "- open a console on the VM:"
echo "  virtctl console testvm"
echo "."

