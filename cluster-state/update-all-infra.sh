#!/bin/bash
infraDir="infra-templates"
mkdir -p $infraDir

helm repo add cilium https://helm.cilium.io/ > /dev/null
helm repo add aqua https://aquasecurity.github.io/helm-charts/ > /dev/null
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/ > /dev/null
helm repo add grafana https://grafana.github.io/helm-charts > /dev/null
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts > /dev/null
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
    --set cgroup.hostRoot=/sys/fs/cgroup \
    --include-crds \
    --output-dir $infraDir

echo " - Updating Spegel"
helm template spegel oci://ghcr.io/spegel-org/helm-charts/spegel -n spegel-system --create-namespace --include-crds -f spegel-values.yaml --output-dir $infraDir
kubectl create namespace spegel-system --dry-run=client -o yaml | sed '/name: spegel-system/a\
  labels:\
    pod-security.kubernetes.io/enforce: privileged' > $infraDir/spegel/templates/namespace.yaml

echo " - Updating Trivy"
helm template trivy-operator aqua/trivy-operator -n trivy-system --create-namespace --include-crds -f trivy-values.yaml --output-dir $infraDir
kubectl create namespace trivy-system --dry-run=client -o yaml > $infraDir/trivy-operator/templates/namespace.yaml

echo " - Updating Local Path Storage Provider"
echo "   - Setting Talos data disk path /var/mnt/data"
echo "   - Setting namespace to have privileged access"
echo "   - Setting local-path-provider to be default storage class"
curl https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.32/deploy/local-path-storage.yaml \
| sed 's|/opt/local-path-provisioner|/var/mnt/data|g' \
| sed '/name: local-path-storage$/a\
  labels:\
    pod-security.kubernetes.io/enforce: privileged' \
| sed '/name: local-path$/a\
  annotations:\
    storageclass.kubernetes.io/is-default-class: "true"' > $infraDir/local-path-storage.yaml

echo " - Updating kubelet-serving-cert-approver"
curl https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/main/deploy/standalone-install.yaml > $infraDir/kubelet-serving-cert-approver.yaml

echo " - Updating metrics-server"
helm template metrics-server metrics-server/metrics-server -n metrics-system --create-namespace --include-crds -f metrics-values.yaml --output-dir $infraDir
kubectl create namespace metrics-system --dry-run=client -o yaml > $infraDir/metrics-server/templates/namespace.yaml

echo " - Updating monitoring namespace"
kubectl create namespace monitoring --dry-run=client -o yaml \
| sed '/name: monitoring$/a\
  labels:\
    pod-security.kubernetes.io/enforce: privileged' > $infraDir/monitoring-namespace.yaml

echo " - Updating prometheus"
helm template prometheus prometheus-community/prometheus -n monitoring --create-namespace --include-crds -f prometheus-values.yaml --output-dir $infraDir

echo " - Updating grafana"
helm template grafana grafana/grafana -n monitoring --create-namespace --include-crds -f grafana-values.yaml --output-dir $infraDir
echo "   - Deleting test directory that we dont want deployed"
rm -rf $infraDir/grafana/templates/tests

echo " - Updating loki"
helm template loki grafana/loki -n monitoring --create-namespace --include-crds --set resources.limits.cpu=500m --set resources.limits.memory=512Mi -f loki-values.yaml --output-dir $infraDir
rm -rf $infraDir/loki/templates/tests

echo " - Updating alloy"
helm template alloy grafana/alloy -n monitoring --create-namespace --include-crds --set resources.limits.cpu=500m --set resources.limits.memory=512Mi -f alloy-values.yaml --output-dir $infraDir
rm -rf $infraDir/alloy/templates/tests


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