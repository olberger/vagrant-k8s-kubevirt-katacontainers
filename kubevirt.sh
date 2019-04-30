#!/bin/bash

kubectl create namespace kubevirt

echo "Activate DataVolumes feature gate"
cat <<EOF | kubectl create -f -
apiVersion: v1
data:
  feature-gates: DataVolumes
kind: ConfigMap
metadata:
  name: kubevirt-config
  namespace: kubevirt
EOF

echo "Deploy kubevirt"
export KUBEVIRT_RELEASE=$(curl --silent "https://api.github.com/repos/kubevirt/kubevirt/releases/latest" | grep '"tag_name":'| sed -E 's/.*"([^"]+)".*/\1/')
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/$KUBEVIRT_RELEASE/kubevirt-operator.yaml
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/$KUBEVIRT_RELEASE/kubevirt-cr.yaml
#kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_RELEASE}/kubevirt.yaml

curl -s -Lo virtctl \
    https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_RELEASE}/virtctl-${KUBEVIRT_RELEASE}-linux-amd64
chmod +x virtctl
sudo mv virtctl /usr/local/bin/

# wait until kubevirt is stated
echo "wait for kubevirt to be started"
kubectl wait --timeout=300s --for=condition=Ready -n kubevirt pod -l kubevirt.io=virt-handler

