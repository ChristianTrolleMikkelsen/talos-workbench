#!/bin/bash

clusterName=talos-$1

(cd ../cluster-state && ./add-cluster-env.sh $clusterName)
cd ../bootstrap

pass-cli login

export GITHUB_TOKEN=$(pass-cli item view --vault-name Personal --item-title "Github PAT (finegrained) for Talos flux" --field Secret)
export GITHUB_USER=ChristianTrolleMikkelsen

./bootstrap-cluster-cpl.sh $clusterName "$2"
./bootstrap-cluster-worker.sh $clusterName "$3"
./bootstrap-cluster-worker.sh $clusterName "$4"
./bootstrap-assign-worker-node-roles.sh $clusterName
./bootstrap-install-cilium.sh $clusterName
./bootstrap-install-fluxcd.sh $clusterName
