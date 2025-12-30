#!/bin/bash

source ~/.bash_profile

echo "Recreating VMs:"

# Stop VMs
echo " - Stopping"
VBoxManage controlvm "talos-cpl-0" poweroff
VBoxManage controlvm "talos-worker-0" poweroff
VBoxManage controlvm "talos-worker-1" poweroff
Sleep 5

# Delete VMs
echo " - Deleting"
VBoxManage unregistervm "talos-cpl-0" --delete
VBoxManage unregistervm "talos-worker-0" --delete
VBoxManage unregistervm "talos-worker-1" --delete
Sleep 5

# Clone VMs
echo " - Cloning"
VBoxManage clonevm "talos-" --name "talos-cpl-0" --register
VBoxManage clonevm "talos-" --name "talos-worker-0" --register
VBoxManage clonevm "talos-" --name "talos-worker-1" --register
Sleep 5

# Start VMs
echo " - Starting"
VBoxManage startvm "talos-cpl-0"
VBoxManage startvm "talos-worker-0"
VBoxManage startvm "talos-worker-1"

echo "Done"