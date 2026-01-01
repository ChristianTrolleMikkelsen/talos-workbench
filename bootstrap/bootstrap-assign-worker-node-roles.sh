#!/bin/bash

echo "Assigning worker roles to nodes:"
#kubectl get nodes --no-headers

echo " - Waiting for 3 nodes to appear..."

TARGET_NODE_COUNT=3

while true; do
  CURRENT_NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)

  if [ "$CURRENT_NODE_COUNT" -ge "$TARGET_NODE_COUNT" ]; then
    echo "    - $CURRENT_NODE_COUNT nodes ready."
    break
  else
    echo "    - Current node count is $CURRENT_NODE_COUNT. Waiting for it to reach $TARGET_NODE_COUNT..."
    sleep 10
  fi
done

echo " - Assigning worker roles to nodes..."

nodes=$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane,!node-role.kubernetes.io/worker' -o json | jq -r '.items[].metadata.name')

for node in $nodes; do
  echo "    - $node"
  kubectl label node $node node-role.kubernetes.io/worker=
done

echo " - Assigning state role to first node..."
first_node=$(echo "$nodes" | head -n 1)
kubectl label node $first_node node-role.kubernetes.io/state=

kubectl get nodes --no-headers
echo " - Worker and state roles assigned."
