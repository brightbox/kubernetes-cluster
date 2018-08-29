# Kubernetes Cluster Builder

## Getting started
Build a Kubernetes Cluster on Brightbox Cloud the easy way. [Read our step-by-step guide on deploying a cluster](https://www.brightbox.com/docs/guides/kubernetes/deploy-kubernetes-on-brightbox-cloud/) and start using Kubernetes today.

## Installing kubectl on your workstation.
The master node has kubectl set up and ready for operation, but you may want to operate your cluster directly from your workstation

- set the `management_source` variable to the appropriate CIDR that includes your workstation, and apply to the cluster with `terraform apply`
- [install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) using a method suitable for your workstation.
- Copy the cluster config from the master node
```
$ mkdir ${HOME}/.kube
$ scp ubuntu@$(terraform output master):.kube/config ~/.kube/config
$ sed -i "s/https:.*$/https:\/\/$(terraform output master):6443/" ~/.kube/config
```
- Check you can connect by running `kubectl cluster-info`

The `download-config.sh` script in the `scripts` directory will copy the cluster config into place for you.

## Running the examples
If you are using kubectl on the master node, copy the examples directory to the master node first
```
scp -r examples ubuntu@$(terrform output master):.
```
### pod-example.yaml
A simple pod configuration that runs the busybox container

- apply the pod
```
kubectl apply -f examples/pod-example.yaml
```
- list the pods created
```
$ kubectl get pods
NAME      READY     STATUS    RESTARTS   AGE
busybox   1/1       Running   0          1m
```
- look at the details of the pod
```
$ kubectl describe pod/busybox
Name:               busybox
Namespace:          default
Priority:           0
PriorityClassName:  <none>
Node:               srv-rmsqz/10.241.205.182
Start Time:         Thu, 23 Aug 2018 12:05:07 +0100
Labels:             <none>
Annotations:        cni.projectcalico.org/podIP=192.168.1.6/32
                    kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"v1","kind":"Pod","metadata":{"annotations":{},"name":"busybox","namespace":"default"},"spec":{"containers":[{"command":["sleep","3600"],...
Status:             Running
IP:                 192.168.1.6
Containers:
  busybox:
    Container ID:  docker://a050e1e6cb92c796fe061b19f0f77524316b0f8fb132fc020d3ffc653aa6e45e
    Image:         busybox
    Image ID:      docker-pullable://busybox@sha256:cb63aa0641a885f54de20f61d152187419e8f6b159ed11a251a09d115fdff9bd
    Port:          <none>
    Host Port:     <none>
    Command:
      sleep
      3600
    State:          Running
      Started:      Thu, 23 Aug 2018 12:05:11 +0100
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-6vdg8 (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  default-token-6vdg8:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-6vdg8
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason     Age   From                Message
  ----    ------     ----  ----                -------
  Normal  Scheduled  2m    default-scheduler   Successfully assigned default/busybox to srv-rmsqz
  Normal  Pulling    2m    kubelet, srv-rmsqz  pulling image "busybox"
  Normal  Pulled     2m    kubelet, srv-rmsqz  Successfully pulled image "busybox"
  Normal  Created    2m    kubelet, srv-rmsqz  Created container
  Normal  Started    2m    kubelet, srv-rmsqz  Started container
```
- The pod will expire itself after an hour, or you can delete it (delete will wait for the pod to exit)
```
kubectl delete -f examples/pod-example.yaml
pod "busybox" deleted
```

### loadbalancer-example.yaml
This runs up a simple http service via a Brightbox Loadbalancer and cloud IP.

- apply the service
```
$ kubectl apply -f examples/loadbalancer-example.yaml
deployment.apps/hello-world created
service/example-service created
```
- wait until the load balancer service obtains a Cloud IP
```
$ kubectl get services
NAME              TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)        AGE
example-service   LoadBalancer   172.30.38.64   109.107.39.75   80:31404/TCP   5m
kubernetes        ClusterIP      172.30.0.1     <none>          443/TCP        19m
```
- check the service works
```
$ curl 109.107.39.75; echo
Hello Kubernetes!
```
- and if you have IPv6, check access over IPv6 to your fully dual stacked service
```
$ kubectl get service/example-service -o yaml | grep 'hostname:'
    - hostname: cip-109-107-39-75.gb1s.brightbox.com
$ curl -v cip-109-107-39-75.gb1s.brightbox.com; echo
* Rebuilt URL to: cip-109-107-39-75.gb1s.brightbox.com/
*   Trying 2a02:1348:ffff:ffff::6d6b:274b...
* TCP_NODELAY set
* Connected to cip-109-107-39-75.gb1s.brightbox.com (2a02:1348:ffff:ffff::6d6b:274b) port 80 (#0)
> GET / HTTP/1.1
> Host: cip-109-107-39-75.gb1s.brightbox.com
> User-Agent: curl/7.58.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Date: Thu, 23 Aug 2018 10:47:48 GMT
< Connection: keep-alive
< Transfer-Encoding: chunked
<
* Connection #0 to host cip-109-107-39-75.gb1s.brightbox.com left intact
Hello Kubernetes!
```
- and finally remove the service
```
kubectl delete -f examples/loadbalancer-example.yml
```
### loadbalancer-annotation-example.yaml
This creates a TCP load balancer on Brightbox Cloud with a bespoke
http healthcheck and 'round-robin' balancing policy by adding special
annotations to the configuration.

Create, test and delete the example in the same way as the previous example.

## Loadbalancer Source IP support
Brightbox Cloud load balancers work in either `Cluster` mode or `Local` mode.

In `Local` mode the source address will always be the address of the
Brightbox Cloud Load Balancer, with the source address of the client
contained in the `X-Forwarded-For` header.

In `Cluster` mode the source address may be another node in the cluster. The `X-Forwarded-For` header is still set to the source address of the end client.

You can see the different responses by following the [Source IP test instructions](https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-type-loadbalancer) on the main k8s documentation site. 

TCP loadbalancers obviously don't have the `X-Forwarded-For` header
set. The source address is set as with HTTP load balancers. See how that
works by creating the TCP protocol annoation on the loadbalancer.

```
kubectl annotate service loadbalancer service.beta.kubernetes.io/brightbox-load-balancer-listener-protocol=tcp
```
