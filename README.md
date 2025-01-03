# Kubernetes Cluster Builder

## Getting started
Build a Kubernetes Cluster on Brightbox Cloud the easy way. [Read our step-by-step guide on deploying a cluster](https://www.brightbox.com/docs/guides/kubernetes/deploy-kubernetes-on-brightbox-cloud/) and start using Kubernetes today.

## Installing kubectl on your workstation.
The master node has kubectl set up and ready for operation, but you may want to operate your cluster directly from your workstation

- set the `management_source` variable to the appropriate CIDR that includes your workstation, and apply to the cluster with `terraform apply`. You can do this automaitcally on the command line with
```
$ terraform apply -var "management_source=[\"$(curl -s ifconfig.co)/32\"]"
```
- [install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) using a method suitable for your workstation.
- Copy the cluster config from the master node
```
$ mkdir ${HOME}/.kube
$ scp ubuntu@$(terraform output master):.kube/config ~/.kube/config
$ sed -i "s/https:.*$/https:\/\/$(terraform output master):6443/" ~/.kube/config
```
- Check you can connect by running `kubectl cluster-info`

The `download-config.sh` script in the `scripts` directory will copy the cluster config into place for you.

## Adding Storage to your cluster

Is described [over here](examples/storage/README.md)

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
works by creating the TCP protocol annotation on the loadbalancer.

```
kubectl annotate service loadbalancer service.beta.kubernetes.io/brightbox-load-balancer-listener-protocol=tcp
```
### loadbalancer-proxy-example.yaml
Brightbox Cloud load balancers support the [Proxy
Protocol](https://www.brightbox.com/docs/reference/load-balancers/#proxy-protocol-support)
allowing the source IP to be obtained easily if your backend software
supports it.  This example creates a Percona database which you can
connect to with a version 8 client.

Apply the example
```
kubectl apply -f examples/loadbalancer-proxy-example.yaml
```
Once the load balancer has completed building, get the pod names
```
kubectl get pods
```
and obtain the root password from the logs
```
$ kubectl logs percona-5cb97df57c-db2p5 | grep GENERATED
GENERATED ROOT PASSWORD: 4q6eNPylWuxykirluM)urIbipoJ
```

Then connect with a mysql client to the load balancer address and run a show process list
```
$ mysql -v -h cip-wyre0.gb1.brightbox.com -e 'show full processlist;' -u root -p
Enter password:
--------------
show full processlist
--------------

+----+-----------------+-------------------+------+---------+------+------------------------+-----------------------+-----------+---------------+
| Id | User            | Host              | db   | Command | Time | State                  | Info                  | Rows_sent | Rows_examined |
+----+-----------------+-------------------+------+---------+------+------------------------+-----------------------+-----------+---------------+
|  4 | event_scheduler | localhost         | NULL | Daemon  |  705 | Waiting on empty queue | NULL                  |         0 |             0 |
| 10 | root            | 192.168.2.1:59186 | NULL | Query   |    0 | starting               | show full processlist |         0 |             0 |
+----+-----------------+-------------------+------+---------+------+------------------------+-----------------------+-----------+---------------+
```
You'll see that the Host address is a local address from the internal kubernetes network.

Now delete the example
```
kubectl delete -f examples/loadbalancer-proxy-example.yaml
```
then edit and uncomment the lines that turn on proxy support in the
loadbalancer and the database, before applying the example again. Remember
to get the new root password.

This time when you connect you'll see that the Host address is the address of the client you are connecting from.
```
$ mysql -v -h cip-wyre0.gb1.brightbox.com -e 'show full processlist;' -u root -p
Enter password:
--------------
show full processlist
--------------

+----+-----------------+----------------------+------+---------+------+------------------------+-----------------------+-----------+---------------+
| Id | User            | Host                 | db   | Command | Time | State                  | Info                  | Rows_sent | Rows_examined |
+----+-----------------+----------------------+------+---------+------+------------------------+-----------------------+-----------+---------------+
|  4 | event_scheduler | localhost            | NULL | Daemon  |   34 | Waiting on empty queue | NULL                  |         0 |             0 |
|  8 | root            | 82.132.242.240:47962 | NULL | Query   |    0 | starting               | show full processlist |         0 |             0 |
+----+-----------------+----------------------+------+---------+------+------------------------+-----------------------+-----------+---------------+
```
## Automatic SSL certificate management
Brightbox Cloud load balancers support [automatic generation of SSL certificates](https://www.brightbox.com/docs/reference/load-balancers/#certificates) via Let's Encrypt.

First create a normal HTTP loadbalancer and test that the loadbalancer works as expected. Obtain the address details via kubectl.
```
$ kubectl expose deployment source-ip-app --name=loadbalancer --port=80 --target-port=8080 --type=LoadBalancer
service/loadbalancer exposed
$ kubectl get service/loadbalancer
NAME           TYPE           CLUSTER-IP      EXTERNAL-IP                                                                                                      PORT(S)        AGE
loadbalancer   LoadBalancer   172.30.73.139   109.107.39.75,2a02:1348:ffff:ffff::6d6b:274b,cip-109-107-39-75.gb1s.brightbox.com,cip-f7uv8.gb1s.brightbox.com   80:31129/TCP   1m
```

Now map a domain name to the allocated cloudIP via your preferred DNS service - either directly to the addresses of the CloudIP or via a CNAME record to the cip DNS name.
Once the domain names resolve correctly, annotate your load balancer with the domain, and change the exposed port to 443.
```
$ kubectl patch service/loadbalancer --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/port", "value":443}]'
service/loadbalancer patched
$ kubectl annotate service loadbalancer service.beta.kubernetes.io/brightbox-load-balancer-ssl-domains=my-domain.co
service/loadbalancer annotated
```
The load balancer will automatically obtain the appropriate SSL
certificates, install them and turn on the HTTPS redirect service. This
will ensure that any access to URLs on the specified domains will go
via a secure connection straightaway.
```
$ curl https://my-domain.co/
```
### Fully Automatic SSL certificate management
You can create an SSL enabled load balancer in one go by specifying an HTTPS listener in your manifest. The SSL certificate requested with be the domain name and reverse name of the cloud IP allocated. Apply the manifest example with `kubectl apply -f load-balancer-ssl-example.yml` to see this in action.

### Automatic SSL certificates with manual Cloud IPs 
If you allocate a cloud IP manually via the [Brightbox Cloud
Manager](https://www.brightbox.com/docs/guides/manager/getting-started/)
you can have finer control over the lifetime of the cloudip. 

- Select or create a new CloudIP in the Brightbox Manager and map your
chosen domain to it either via a CNAME record or directly to the addresses
shown in the Manager. You may want to set the reverse DNS on the CloudIP too.
- Make a copy of the `load-balancer-ssl-annotation-example.yml` manifest and edit it.
- Enter the id of your cloud IP against the `brightbox-load-balancer-cloudip-allocations` annotation
- Apply the manifest with `kubectl apply -f`

The load balancer will automatically obtain the appropriate SSL certificates and install them. Once they are in place you can access via an https URL

## Upgrade a Cluster
The scripts will upgrade the version of Kubernetes on an existing cluster. Change the `kubernetes_release` version number as required and run `terraform apply`. Both the master and workers will be upgraded to the new version.
Upgrades will only work if permitted by the `kubeadm upgrade` facility. You can check before hand by logging onto your master and running [`kubeadm upgrade plan`](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-upgrade/#cmd-upgrade-plan)
## Adding Workers
You can add by changing the `worker_count` variable
and running `terraform apply`. You can also change the `worker_type` and
even the `image_desc` and new workers will use those values.

## Reducing workers
Before reducing the `worker_count` variable, you will need to drain
and remove the nodes from Kubernetes.  Reducing workers operates using
the last in, first out principle. Run

    $ terraform output

and select the `worker_ids` that are at thoe bottom of their lists.

Run

    kubectl drain srv-abcde --ignore-daemonsets=true

for each node. Then

    kubectl delete nodes srv-abcde srv-edcba

Finally reduce the `worker_count` variable and run `terraform apply`
