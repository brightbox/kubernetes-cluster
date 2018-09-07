#!/bin/sh
# Download the config from the current cluster to the kubectl config
# area on the current workstation
set -e
mkdir -p $HOME/.kube
scp ubuntu@$(terraform output master):.kube/config ~/.kube/config
sed -i "s/https:.*$/https:\/\/$(terraform output master):6443/" ~/.kube/config
