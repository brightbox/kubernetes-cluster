# Installing the Metrics Server using Helm

The metrics server can be difficult to install on Kubeadm clusters as it struggles with the PKI structure kubeadm puts in place

You have to use a values file with Helm or the installation will not work properly (and it will be difficult to uninstall). 

At the moment the workaround is to turn it off :-(

```
helm install --set 'args={--kubelet-insecure-tls}' --namespace kube-system metrics stable/metrics-server
```
