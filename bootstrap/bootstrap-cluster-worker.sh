#!/bin/bash

usage() {
  echo "Usage: $0 --env <env> --workerIp <ip>"
  exit 1
}

clusterName=$1
workerIp=$2
configPath=$clusterName

mkdir -p $configPath

talosctl apply-config --insecure --nodes $workerIp --file $configPath/worker.yaml

while true; do
  current_node_count=$(kubectl get nodes --no-headers | wc -l)
  if [[ $current_node_count -ge 1 ]]; then
    echo "Worker node appeared."
    break
  else
    echo "Waiting for worker node..."
    sleep 5
  fi
done
