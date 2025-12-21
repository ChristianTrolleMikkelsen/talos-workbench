#!/bin/bash

usage() {
  echo "Usage: $0 --env <env> --cplIp <ip>"
  exit 1
}

clusterName=$1
cplIp=$2
configPath=state/$clusterName

mkdir -p $configPath

echo "Bootstrapping control plane node at $cplIp"
echo " cluster: $clusterName"
echo " state: $configPath"

talosctl gen config $clusterName https://$cplIp:6443 --config-patch @cni-patch.yml --output-dir $configPath --force
talosctl apply-config --insecure --nodes $cplIp --file $configPath/controlplane.yaml

export TALOSCONFIG=$(readlink -f "$configPath/talosconfig")
talosctl --talosconfig $TALOSCONFIG config endpoint $cplIp
talosctl --talosconfig $TALOSCONFIG config node $cplIp

echo " - Talosconfig exported: $TALOSCONFIG"
echo " - Waiting for Talos control plane to be ready for bootstrap..."
echo " - Press any key to continue..."
read -n 1 -s

talosctl --talosconfig $TALOSCONFIG bootstrap

talosctl --talosconfig $TALOSCONFIG kubeconfig .
export KUBECONFIG=$(pwd)/kubeconfig  

echo " - Talosconfig after bootstrap and kubeconfig export: $TALOSCONFIG"

while true; do
  current_node_count=$(kubectl get nodes --no-headers | wc -l)
  if [[ $current_node_count -ge 0 ]]; then
    echo " - Cpl node appeared."
    break
  else
    echo " - Waiting for cpl node..."
    sleep 5
  fi
done
