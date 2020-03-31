#!/bin/sh
# Download the config from the current cluster to the kubectl config
# area on the current workstation
set -e
mkdir -p $HOME/.kube
if [ -f inventory/artifacts/admin.conf ]
then
    cp inventory/artifacts/admin.conf $HOME/.kube/config
else
    scp ubuntu@$(terraform output bastion):.kube/config $HOME/.kube/config
fi
sed -i "s/https:.*$/https:\/\/$(terraform output apiserver):6443/" $HOME/.kube/config
