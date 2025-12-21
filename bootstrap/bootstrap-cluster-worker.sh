#!/bin/bash

usage() {
  echo "Usage: $0 --env <env> --workerIp <ip>"
  exit 1
}

clusterName=$1
workerIp=$2
configPath=state/$clusterName

mkdir -p $configPath

echo "Bootstrapping worker node at $workerIp"
echo " cluster: $clusterName"
echo " state: $configPath"
echo " talosconfig before export: $TALOSCONFIG"
export TALOSCONFIG=$(readlink -f "$configPath/talosconfig")
echo " talosconfig after export: $TALOSCONFIG"

talosctl apply-config --insecure --nodes $workerIp --file $configPath/worker.yaml

echo " - Waiting for Talos worker to be ready..."
echo " - Press any key to continue..."
read -n 1 -s

echo " - Waiting 10s for overview of nodes..."
sleep 10

kubectl get nodes
