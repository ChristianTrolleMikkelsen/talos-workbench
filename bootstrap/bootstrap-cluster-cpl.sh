#!/bin/bash

usage() {
  echo "Usage: $0 --env <env> --cplIp <ip>"
  exit 1
}

clusterName=$1
cplIp=$2
configPath=state/$clusterName
cplConfig=$configPath/controlplane.yaml
workerConfig=$configPath/worker.yaml

mkdir -p $configPath

echo "Bootstrapping control plane node at $cplIp"
echo " cluster: $clusterName"
echo " state: $configPath"

echo " generating basic machine configs..."
talosctl gen config $clusterName https://$cplIp:6443 --output-dir $configPath --force

echo " pathcing cni..."
talosctl machineconfig patch $cplConfig --patch @cni-patch.yml -o $cplConfig
talosctl machineconfig patch $workerConfig --patch @cni-patch.yml -o $workerConfig

echo " patching disks..."
talosctl machineconfig patch $workerConfig --patch @disk-patch.yml -o $workerConfig

echo " patching for rotate-server-certificates to enable monitoring..."
talosctl machineconfig patch $cplConfig --patch @metrics-patch.yml -o $cplConfig
talosctl machineconfig patch $workerConfig --patch @metrics-patch.yml -o $workerConfig

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
echo "Done"
