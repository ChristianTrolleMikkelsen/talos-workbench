#!/bin/bash

usage() {
  echo "Usage: $0 --env <env> --cplIp <ip>"
  exit 1
}

clusterName=$1
cplIp=$2
configPath=state/$clusterName
cplConfig=$configPath/controlplane.yaml
vmWorkerConfig=$configPath/worker.yaml
mbaWorkerConfig=$configPath/mba-worker.yaml
nvrWorkerConfig=$configPath/nvr-worker.yaml

mkdir -p $configPath

echo "Bootstrapping control plane node at $cplIp"
echo " cluster: $clusterName"
echo " state: $configPath"

echo " generating basic machine configs..."
talosctl gen config $clusterName https://$cplIp:6443 --output-dir $configPath --force

echo " pathcing cni..."
talosctl machineconfig patch $cplConfig --patch @cni-patch.yml -o $cplConfig
talosctl machineconfig patch $vmWorkerConfig --patch @cni-patch.yml -o $vmWorkerConfig

echo " patching for rotate-server-certificates to enable monitoring..."
talosctl machineconfig patch $cplConfig --patch @metrics-patch.yml -o $cplConfig
talosctl machineconfig patch $vmWorkerConfig --patch @metrics-patch.yml -o $vmWorkerConfig

echo " generating specific worker configs for mba and nvr..."
cp -f $vmWorkerConfig/worker.yaml $mbaWorkerConfig
cp -f $vmWorkerConfig/worker.yaml $nvrWorkerConfig
echo "   patching specific worker configs..."

echo "     patching vm disks to have /dev/sdb for data..."
talosctl machineconfig patch $vmWorkerConfig --patch @disk-patch.yml -o $vmWorkerConfig

#MBA only have 1 disk, for now we dont do anything special
#echo "     patching mba disks..."
#talosctl machineconfig patch $mbaWorkerConfig --patch @disk-patch.yml -o $mbaWorkerConfig

#NVR
#echo "     patching nvr disks..."
#talosctl machineconfig patch $nvrWorkerConfig --patch @disk-patch.yml -o $nvrWorkerConfig

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
