#!/bin/bash

usage() {
  echo "Usage: $0 --env <env>"
  exit 1
}

clusterName=$1

#brew install fluxcd/tap/flux

#curl -fsSL https://proton.me/download/pass-cli/install.sh | bash

pass-cli login

export GITHUB_TOKEN=$(pass-cli item view --vault-name Personal --item-title "Github PAT (finegrained) for Talos flux" --field Secret)
export GITHUB_USER=ChristianTrolleMikkelsen

flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=talos-workbench \
  --branch=main \
  --path=./cluster-state/$clusterName \
  --personal
