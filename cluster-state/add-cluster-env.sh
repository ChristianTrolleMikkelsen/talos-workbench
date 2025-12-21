#!/bin/bash

usage() {
  echo "Usage: $0 --env <env>"
  exit 1
}

clusterName=$1

mkdir -p $clusterName

./update-all-infra.sh
./update-all-apps.sh
