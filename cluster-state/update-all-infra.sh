#!/bin/bash
infraDir="infra-templates"

echo "Updating infra components"
echo " - Updating helm repos"
helm repo add cilium https://helm.cilium.io/ > /dev/null
helm repo update > /dev/null

echo " - Generating templates for infrastructure components"
mkdir -p $infraDir
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