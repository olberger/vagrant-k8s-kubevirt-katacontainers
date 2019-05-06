#!/bin/bash

echo "Install Containerized Data Importer for KubeVirt"

# Source: https://github.com/kubevirt/containerized-data-importer

export VERSION=$(curl -s https://github.com/kubevirt/containerized-data-importer/releases/latest | grep -o "v[0-9]\.[0-9]*\.[0-9]*")
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator-cr.yaml

#operator
kubectl wait --timeout=300s --for=condition=Ready -n cdi pod -l name=cdi-operator
#deployment
kubectl wait --timeout=300s --for=condition=Ready -n cdi pod -l app=containerized-data-importer
#cdi-apiserver
kubectl wait --timeout=300s --for=condition=Ready -n cdi pod -l cdi.kubevirt.io=cdi-apiserver
#cdi-uploadproxy
kubectl wait --timeout=300s --for=condition=Ready -n cdi pod -l cdi.kubevirt.io=cdi-uploadproxy
