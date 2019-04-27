#!/bin/bash

echo "Installing Kata-Containers"
kubectl apply -f https://raw.githubusercontent.com/kata-containers/packaging/master/kata-deploy/kata-rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/kata-containers/packaging/master/kata-deploy/kata-deploy.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/node-api/master/manifests/runtimeclass_crd.yaml
kubectl apply -f https://raw.githubusercontent.com/clearlinux/cloud-native-setup/master/clr-k8s-examples/8-kata/kata-qemu-runtimeClass.yaml

#kubectl get pod -n kube-system
kubectl wait --timeout=180s --for=condition=Ready -n kube-system pod -l name=kata-deploy
