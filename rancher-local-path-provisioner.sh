#!/bin/bash

echo "Install Rancher's Local Path Provisioner"

# Deploy https://github.com/rancher/local-path-provisioner

# Local storage :
LOCALPATH=/opt/local-path-provisioner
echo "Creating local path storage pool in: $LOCALPATH"
sudo mkdir -p $LOCALPATH

# Deploy it
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

# Make local-path the default storage class
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# wait until it's started
kubectl wait --timeout=300s --for=condition=Ready pod -n local-path-storage -l app=local-path-provisioner
