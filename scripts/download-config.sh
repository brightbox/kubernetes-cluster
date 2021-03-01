#!/bin/sh
# Download the config from the current cluster to the kubectl config
# area on the current workstation
set -e
mkdir -p $HOME/.kube
scp ubuntu@$(terraform output -raw bastion):.kube/config ~/.kube/config
sed -i "s/https:.*$/https:\/\/$(terraform output -raw master):6443/" ~/.kube/config
