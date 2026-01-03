#!/bin/bash

source ~/.bash_profile

clusterName=talos-$1

(cd ../cluster-state && ./add-cluster-env.sh $clusterName)
cd ../bootstrap

pass-cli login

export GITHUB_TOKEN=$(pass-cli item view --vault-name Personal --item-title "Github PAT (finegrained) for Talos flux" --field Secret)
export GITHUB_USER=ChristianTrolleMikkelsen

./bootstrap-cluster-cpl.sh $clusterName "$2"
./bootstrap-wait-for-cluster-to-be-ready.sh
./bootstrap-approve-kubelet-certificate.sh
./bootstrap-cluster-worker.sh $clusterName "$3" "worker.yaml"
./bootstrap-cluster-worker.sh $clusterName "$4" "worker.yaml"
#./bootstrap-cluster-mba-worker.sh $clusterName "$5" "mba-worker.yaml"
#./bootstrap-cluster-nvr-worker.sh $clusterName "$6" "nvr-worker.yaml"
./bootstrap-assign-worker-node-roles.sh $clusterName
./bootstrap-install-cilium.sh $clusterName
./bootstrap-install-fluxcd.sh $clusterName
./bootstrap-set-creds.sh $clusterName

echo "All done!"
