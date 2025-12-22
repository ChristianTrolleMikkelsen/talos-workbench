#!/bin/bash
infraDir="infra-templates"
mkdir -p $infraDir

helm repo add cilium https://helm.cilium.io/ > /dev/null
helm repo add trivy https://helm.cilium.io/ > /dev/null
helm repo update > /dev/null

echo "Updating infra components"
echo " - Updating Cilium"

echo " - Generating templates for infrastructure components"
helm template \
    cilium \
    cilium/cilium \
    --version 1.18.5 \
    --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=false \
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set cgroup.autoMount.enabled=false \
    --set cgroup.hostRoot=/sys/fs/cgroup > $infraDir/cilium.yaml

echo " - Updating Spegel"
spegelns=$(kubectl create namespace spegel --dry-run=client -o yaml | sed '/name: spegel/a\
  labels:\
    pod-security.kubernetes.io/enforce: privileged')
helm template spegel oci://ghcr.io/spegel-org/helm-charts/spegel -n spegel -f spegel-values.yaml > $infraDir/spegel.yaml
echo "---\n$spegelns\n" >> $infraDir/spegel.yaml

echo " - Updating Trivy"
trivyns=$(kubectl create namespace trivy-system --dry-run=client -o yaml)
helm template trivy-operator oci://ghcr.io/aquasecurity/helm-charts/trivy-operator -n trivy-system -f trivy-values.yaml > $infraDir/trivy.yaml
echo "---\n$trivyns\n" >> $infraDir/trivy.yaml


for folder in "."/*; do
  if [ -d "$folder" ]; then
    folder_name=$(basename "$folder")

    if [ "$folder_name" != "$infraDir" ]; then
        echo "   - Updating environment: $folder"
        mkdir -p "$folder/infra"
        cp -rf "$infraDir"/* "$folder/infra"
    fi   
  fi
done

rm -r "$infraDir"