#!/bin/bash

clusterName=talos-$1

(cd ../cluster-state && ./add-cluster-env.sh $clusterName)
cd ../bootstrap

./bootstrap-cluster-cpl.sh $clusterName "$2"
./bootstrap-cluster-worker.sh $clusterName "$3"
./bootstrap-cluster-worker.sh $clusterName "$4"
./bootstrap-assign-worker-node-roles.sh $clusterName
./bootstrap-install-fluxcd.sh $clusterName
