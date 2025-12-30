#!/bin/bash

usage() {
  echo "Usage: $0 --env <env>"
  exit 1
}

clusterName=$1
configPath=../cluster-state/$clusterName

echo "Installing Cilium as a pre-requisite CNI for cluster:"
kubectl apply -f $configPath/infra/cilium --recursive

echo " - Waiting for rollout to complete..."
kubectl rollout status daemonset/cilium -n kube-system
kubectl rollout status daemonset/cilium-envoy -n kube-system
kubectl rollout status deployment/cilium-operator -n kube-system
echo "Done"
