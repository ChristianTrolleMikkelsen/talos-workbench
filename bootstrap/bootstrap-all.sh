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
./bootstrap-cluster-worker.sh $clusterName "$3"
./bootstrap-cluster-worker.sh $clusterName "$4"
./bootstrap-assign-worker-node-roles.sh $clusterName
./bootstrap-install-cilium.sh $clusterName
./bootstrap-install-fluxcd.sh $clusterName

echo "All done!"

echo "Save logins locally:"
echo " - Headlamp..."
headlamp_token=$(kubectl create token headlamp -n kube-system)
echo $headlamp_token > state/$clusterName/headlamp.token
echo " - Grafana..."
grafana_token=$(kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
echo $grafana_token > state/$clusterName/grafana.token