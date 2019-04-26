#!/bin/bash

echo "Deploy kubevirt"
export KUBEVIRT_RELEASE=v0.15.0
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/$KUBEVIRT_RELEASE/kubevirt-operator.yaml
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/$KUBEVIRT_RELEASE/kubevirt-cr.yaml

curl -q -Lo virtctl \
    https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_RELEASE}/virtctl-${KUBEVIRT_RELEASE}-linux-amd64
chmod +x virtctl
sudo mv virtctl /usr/local/bin/
