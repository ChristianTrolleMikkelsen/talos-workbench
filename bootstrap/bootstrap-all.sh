#!/bin/bash

clusterName=talos-$1

./bootstrap-cluster-cpl.sh $clusterName "$2"
./bootstrap-cluster-worker.sh $clusterName "$3"
./bootstrap-assign-worker-node-roles.sh $clusterName
./bootstrap-install-fluxcd.sh $clusterName
