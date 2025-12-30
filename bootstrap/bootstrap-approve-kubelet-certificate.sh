#!/bin/bash
echo "Waiting for kubelet CSR's to be ready..."
while true; do
  CSR=$(kubectl get csr --no-headers | grep "system:node" | grep "Pending")

  if [ -n "$CSR" ]; then
    certName=$(echo "$CSR" | awk '{print $1}')
    echo " - Pending CSR with requester 'system:node' found: $certName"
    echo " - Approving manually until auto approver is installed..."
    kubectl certificate approve $certName
    break
  else
    echo " - Waiting for pending node CSR with requester 'system:node' in 'pending' to appear..."
    sleep 10
  fi
done

echo "Done"
