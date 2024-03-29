# Installing the Metrics Server insecurely

The Metrics Server can be difficult to install on kubeadm-managed clusters as it
struggles a little with the PKI structure kubeadm puts in place.

You can work around the problem and install it in a semi-secure manner via helm

    #!shell
    helm install --set 'args={--kubelet-insecure-tls}' --namespace kube-system metrics stable/metrics-server

# Installing the Metrics Server securely

## Setting up a secure channel to the Extension API

Metrics-server is an API extension service. This means that the apiserver
container in Kubernetes talks to the metrics-server and asks it to perform
tasks. To do that securely apiserver has to be able to validate the
certificate that metrics server presents when apiserver asks for a connection
and metrics-server has to be able to validate the client certificate
apiserver presents alongside its connection request.

The first step is to generate a CA we can add to the `caBundle` attribute
of the APIRequest object, and use it to sign a certificate that metrics-server
serves when apiserver connects to it. Then append the CA to that
certificate so the file contains both the serving certificate and the
signing CA.

The serving certificate must use a Subject Additional Name (SAN) alongside
the Common Name and the name must be `metrics-server.kube-system.svc`. Go
from 1.15 onwards objects to using a Common Name only with a `x509:
certificate relies on legacy Common Name field` error.

The certificate bundle and the private key should be added to a Kubernetes
certificate secret and mounted in place on the metrics server pod so
metrics-server can read the files.

You then get metrics-server to read the certificate and key by providing the
following arguments

    #!shell
    --tls-cert-file=/etc/kubernetes/pki/apiserver/tls.crt
    --tls-private-key-file=/etc/kubernetes/pki/apiserver/tls.key

The client side - metrics-server talking to apiserver securely - is
already setup via the RBAC and service account setups in the standard
configuration.

The pattern above can be used to create a PKI secure connection to any
API extension server and eliminate `insecureSkipTLSVerify: true` from
the APIRequest object.

## Setting Up a secure channel to Kubelet

Creating a secure connection to kubelet is rather more challenging. By
default all the kubelets installed by kubeadm serve a self-signed
certificate, which obviously cannot then be verified by metrics-server.
Hence the `--kubelet-insecure-tls` flag in the workaround.

However you can ask kubelet to request a central signing certificate
from the control plane by adding `serverTLSBootstrap: true` to the
kubelet configuration (either directly or in the kubeadm config). Then
when kubelet starts up it will request a certificate which you can view
using `kubectl get csr` and approve with `kubectl certificate approve`.

Once kubelet is using a centrally allocated certificate, the metrics-server 
needs to be constrained and run on a master node so that it can
mount and read the main control plane CA.

You can then get metrics-server to read the CA by passing the following argument

    #!shell
    --kubelet-certificate-authority=/etc/kubernetes/pki/ca/ca.crt

Once again the client side is already handled by the front-proxy process
and kubelet has no trouble verifying the client certificate presented
by the metrics-server.

## Deploying secure metrics server using the Brightbox manifests

We've encapsulated the process within the [Brightbox Kubernetes Terraform
manifests](https://github.com/brightbox/kubernetes-cluster). To build
a cluster with kubelets using centrally signed certificates, set
the `secure_kublet` variable to `true`. Remember to approve the kubelet
certificates with kubectl as soon as you have access to the control plane
(with `kubectl get csr` and approve with `kubectl certificate approve`
as above).

Then generate the metrics-server signing certificates

    #!shell
    sh examples/metrics/generate-cert.sh

And finally apply a kustomized manifest to load the secure metrics-server

    #!shell
    kubectl apply -k examples/metrics
