#!/bin/bash
clusterName=$1

echo "Ensure login creds:"
echo " - Headlamp... generating sa token and updating in ProtonPass"
kubectl rollout status deployment/headlamp -n kube-system
headlamp_token=$(kubectl create token headlamp -n kube-system)
echo $headlamp_token > state/$clusterName/headlamp.token
echo "   - Saved to: state/$clusterName/headlamp.token"

pass-cli item update --vault-name Personal --item-title "Headlamp admin pwd for Talos k8s" --field Secret=$headlamp_token
echo "   - Saved to ProtonPass: Headlamp admin pwd for Talos k8s"

echo " - Grafana... fetching password from ProtonPass"
kubectl rollout status deployment/grafana -n monitoring
grafana_token=$(pass-cli item view --vault-name Personal --item-title "Grafana admin pwd for Talos k8s" --field Secret)
echo $grafana_token > state/$clusterName/grafana.token
echo "   - Saved to: state/$clusterName/grafana.token"
grafanaEncoded=$(echo -n $grafana_token | base64 -b 0)
#kubectl patch secret -n monitoring grafana -p="{\"data\":{\"admin-password\":\"$grafanaEncoded\"}}"
#echo "   - K8s secret patched"
kubectl create secret -n monitoring generic proton-grafana-admin \
  --from-literal=admin-user=admin \
  --from-literal=admin-password=$grafanaEncoded
echo "   - secret created/updated: proton-grafana-admin"
echo "Done"