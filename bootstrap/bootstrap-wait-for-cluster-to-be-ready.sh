#!/bin/bash

echo "Waiting for cluster to be ready..."
while true; do
  if kubectl cluster-info &> /dev/null; then
    echo " - Cluster is ready!"
    break
  else
    echo " - Waiting for cluster to ready..."
    sleep 10
  fi
done

echo "Done"