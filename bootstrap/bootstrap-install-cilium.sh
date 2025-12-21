#!/bin/bash

usage() {
  echo "Usage: $0 --env <env>"
  exit 1
}

clusterName=$1
configPath=state/$clusterName

echo "Installing Cilium as a pre-requisite CNI for cluster:"
kubectl apply -f $configPath/infra

echo " - Waiting for rollout to complete..."
kubectl rollout status daemonset/cilium
kubectl rollout status daemonset/cilium-envoy
kubectl rollout status deployment/cilium-operator
