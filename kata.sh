#!/bin/bash

# Finally, install Kata-Containers

# source: https://github.com/kata-containers/packaging/tree/master/kata-deploy#kubernetes-quick-start
echo "Installing Kata-Containers"
kubectl apply -f https://raw.githubusercontent.com/kata-containers/packaging/master/kata-deploy/kata-rbac.yaml

# That fellow will configure much of the stuff
kubectl apply -f https://raw.githubusercontent.com/kata-containers/packaging/master/kata-deploy/kata-deploy.yaml

# Again the progress bar
print_progress() {
    percentage=$1
    chars=$(echo "40 * $percentage"/1| bc)
    v=$(printf "%-${chars}s" "#")
    s=$(printf "%-$((40 - chars))s")
    echo "${v// /#}""${s// /-}"
}

running_system_pods=0
total_system_pods=$(kubectl get pods --all-namespaces | tail -n +2 | wc -l)
while [ $running_system_pods -lt $total_system_pods ]
do
    running_system_pods=$(kubectl get pods --all-namespaces | grep Running | wc -l)
    percentage="$( echo "$running_system_pods/$total_system_pods" | bc -l )"
    echo -ne $(print_progress $percentage) "${YELLOW}Installing additional infrastructure components...${NC}\r"
    sleep 1
done

# Clear line and print finished progress
echo -ne "$pc%\033[0K\r"
echo -ne $(print_progress 1) "${GREEN}Done.${NC}\n"


# Now, configure the Kata runtime
# This should be the "modern" way of doing so compatible with the runtimeClasses recently introduced in k8s

# We reuse the values previously set in the config file, and add the kata stuff
cat  <<EOF | sudo tee /etc/containerd/config.toml
[debug]
  level = "info"
[plugins]
  [plugins.cri]
    systemd_cgroup = true
    [plugins.cri.containerd]
      [plugins.cri.containerd.runtimes.kata]
        runtime_type = "io.containerd.kata.v2"
EOF

# Restart containerd
sudo systemctl restart containerd

# This is no longer needed, as runtimeClasses are supported already
#kubectl get runtimeclasses
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/node-api/master/manifests/runtimeclass_crd.yaml

# Bind the kata and kata-qemu runtime classes to their handlers (the plugins.cri.containerd.runtimes above ?)
#kubectl apply -f https://raw.githubusercontent.com/clearlinux/cloud-native-setup/master/clr-k8s-examples/8-kata/kata-qemu-runtimeClass.yaml
kubectl apply -f https://raw.githubusercontent.com/kata-containers/packaging/master/kata-deploy/k8s-1.14/kata-qemu-runtimeClass.yaml

# Wait until it's deployed
kubectl wait --timeout=180s --for=condition=Ready -n kube-system pod -l name=kata-deploy

# From now on, that should be working.

# Check the CRI config with:
# sudo crictl info

# $ cat > pod-kata.yaml << EOF
# apiVersion: v1
# kind: Pod
# metadata:
#   name: foobar-kata
# spec:
#   runtimeClassName: kata
#   containers:
#   - name: nginx
#     image: nginx
# EOF
# $ kubectl apply -f pod-kata.yaml
# pod/foobar-kata created

# Or with the example in /vagrant/ :
# kubectl apply -f nginx-untrusted.yaml
# kubectl describe pod nginx-untrusted
