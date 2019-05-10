#!/bin/bash

# Activate a CNI component for the network

# This is needed for progress bar display
sudo apt-get install -y bc

echo "Deploy calico network"
# deploy calico network
kubectl apply -f https://docs.projectcalico.org/v3.6/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml

sleep 5

# Progres bar hack borowed from Antidote/selfmedicate
print_progress() {
    percentage=$1
    chars=$(echo "40 * $percentage"/1| bc)
    v=$(printf "%-${chars}s" "#")
    s=$(printf "%-$((40 - chars))s")
    echo "${v// /#}""${s// /-}"
}

echo "wait for calico to be started"
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


#kubectl wait --timeout=180s --for=condition=Ready -n kube-system pod -l k8s-app=calico-kube-controllers
#kubectl wait --timeout=180s --for=condition=Ready -n kube-system pod -l k8s-app=calico-node

# get componentstats
#kubectl get componentstatus
