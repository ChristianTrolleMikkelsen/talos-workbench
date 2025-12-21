#!/bin/bash

echo "Assigning worker roles to nodes:"
kubectl get nodes --no-headers

nodes=$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane,!node-role.kubernetes.io/worker' -o json | jq -r '.items[].metadata.name')

for node in $nodes; do
  echo " - Assigning worker: $node"
  kubectl label node $node node-role.kubernetes.io/worker=
done
