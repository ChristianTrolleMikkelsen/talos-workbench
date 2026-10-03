#!/bin/bash

usage() {
  echo "Usage: $0 --env <env>"
  exit 1
}

clusterName=$1

#brew install fluxcd/tap/flux
curl -s https://fluxcd.io/install.sh | bash

#curl -fsSL https://proton.me/download/pass-cli/install.sh | bash

kubectl get pods -A

flux bootstrap github \
  --owner=ChristianTrolleMikkelsen \
  --repository=talos-workbench \
  --branch=main \
  --path=./cluster-state/$clusterName \
  --personal
echo "Done"
