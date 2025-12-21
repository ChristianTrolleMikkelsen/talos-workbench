#!/bin/bash

usage() {
  echo "Usage: $0 --env <env> --cplIp <ip>"
  exit 1
}

clusterName=$1
cplIp=$2
configPath=state/$clusterName

mkdir -p $configPath

talosctl gen config $clusterName https://$cplIp:6443 --config-patch @cni-patch.yml --output-dir $configPath --force
talosctl apply-config --insecure --nodes $cplIp --file $configPath/controlplane.yaml

export TALOSCONFIG="$configPath/talosconfig"
talosctl --talosconfig $TALOSCONFIG config endpoint $cplIp
talosctl --talosconfig $TALOSCONFIG config node $cplIp

sleep 180

talosctl --talosconfig $TALOSCONFIG bootstrap

talosctl --talosconfig $TALOSCONFIG kubeconfig .
export KUBECONFIG=$(pwd)/kubeconfig  

while true; do
  current_node_count=$(kubectl get nodes --no-headers | wc -l)
  if [[ $current_node_count -ge 0 ]]; then
    echo "Cpl node appeared."
    break
  else
    echo "Waiting for cpl node..."
    sleep 5
  fi
done