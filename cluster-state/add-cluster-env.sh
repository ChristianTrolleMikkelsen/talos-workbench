#!/bin/bash

usage() {
  echo "Usage: $0 --env <env>"
  exit 1
}

clusterName=$1

mkdir -p $clusterName

./update-all-infra.sh
./update-all-apps.sh

git add $clusterName
git commit -m "Added cluster environment $clusterName"
git push origin main
