## GlusterFS

GlusterFS is a scalable network filesystem suitable for data-intensive
tasks such as cloud storage and media streaming.
GlusterFS can be used natively by Kubernetes as a client, however the
server has to be set up manually to work effectively at present. This
can be elsewhere on Brightbox Cloud or on the Cluster nodes themselves.

### Installation

The GlusterFS client is installed on all nodes as part of the cluster
installation. Setting up Kubernetes to use Gluster is then a matter of
creating the correct endpoints and Persistent Volume to point at Gluster.

Obtain the name of the gluster volume from the gluster server
```
ubuntu@srv-pe288:~$ sudo gluster volume status
Status of volume: gv0
Gluster process                             TCP Port  RDMA Port  Online  Pid
------------------------------------------------------------------------------
Brick srv-pe288.gb1.brightbox.com:/export/
local_brick                                 49152     0          Y       25063
Brick srv-425y7.gb1.brightbox.com:/export/
local_brick                                 49152     0          Y       2044 
Self-heal Daemon on localhost               N/A       N/A        Y       25084
Self-heal Daemon on srv-425y7               N/A       N/A        Y       2065 
 
Task Status of Volume gv0
------------------------------------------------------------------------------
There are no active volume tasks
```
Create and install the persistent volume relating to the Gluster volume. 
```
$ ./scripts/gluster-pv gv0 5Gi srv-pe288.gb1.brightbox.com srv-425y7.gb1.brightbox.com | kubectl apply -f -
endpoints/glusterfs-cluster configured
persistentvolume/gluster-volume-gv0 created
$ kubectl get pv
NAME                 CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
gluster-volume-gv0   5Gi        RWX            Retain           Available                                   8s
```
Any volume claim created can be mounted by any pod on any worker node. 

### File permissions
Rudimentary security for the Gluster volume comes from creating multiple
PVs with [differing GID annotations](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/#access-control). 

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv1
  annotations:
    pv.beta.kubernetes.io/gid: "1234"
```

Pods that mount a volume with a GID annotation run with that GID, allowing
the administrator to set access to subdirectories on the Gluster volume
by GID.

Pods have to run as a non-root user to make this work.
###Resetting Persistent Volumes
If you accidentally delete the Volume Claim, then the Gluster PV will enter Released mode. To return it to Available just rerun the initial creation command
```
$ ./scripts/gluster-pv gv0 5Gi srv-pe288.gb1.brightbox.com srv-425y7.gb1.brightbox.com | kubectl apply -f -
endpoints/glusterfs-cluster configured
persistentvolume/gluster-volume-gv0 created
```
This removes and resets the claimRef. 

##Example
### gluster-deployment.yaml
This example creates a set of pods on each node that writes to a central test file concurrently.

- apply the set
```
$ kubectl apply -f examples/storage/gluster/gluster-deployment.yaml 
persistentvolumeclaim/gluster-pvc1 created
deployment.apps/gluster-test created
deployment.apps/gluster-test-reader created
```
- check the bindings have all worked as expected
```
$ kubectl get pods
NAME                                   READY   STATUS    RESTARTS   AGE
gluster-test-7c795888b8-7c2tf          1/1     Running   0          23s
gluster-test-7c795888b8-jbdb6          1/1     Running   0          23s
gluster-test-7c795888b8-p4vnz          1/1     Running   0          23s
gluster-test-reader-69dd8f7bd9-h28bc   1/1     Running   0          23s
$ kubectl get pvc
NAME           STATUS   VOLUME               CAPACITY   ACCESS MODES   STORAGECLASS   AGE
gluster-pvc1   Bound    gluster-volume-gv0   5Gi        RWX                           57s
$ kubectl get pv
NAME                 CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                  STORAGECLASS   REASON   AGE
gluster-volume-gv0   5Gi        RWX            Retain           Bound    default/gluster-pvc1                           99m
```
- check that the pods are writing to the persistent volume
```
$ kubectl logs gluster-test-reader-69dd8f7bd9-h28bc
Wed Aug  7 13:33:06 UTC 2019
This is gluster-test-7b7fd888bb-j749m, count=4
Wed Aug  7 13:33:16 UTC 2019
This is gluster-test-7b7fd888bb-7shjv, count=4
Wed Aug  7 13:33:16 UTC 2019
This is gluster-test-7b7fd888bb-pvt25, count=4
Wed Aug  7 13:33:16 UTC 2019
This is gluster-test-7b7fd888bb-j749m, count=4
```
- once you've finished remove the pods
```
$ kubectl delete -f examples/storage/gluster/gluster-deployment.yaml 
persistentvolumeclaim "gluster-pvc1" deleted
deployment.apps "gluster-test" deleted
deployment.apps "gluster-test-reader" deleted
```
- Reset the gluster volume
```
$ ./scripts/gluster-pv gv0 5Gi srv-pe288.gb1.brightbox.com srv-425y7.gb1.brightbox.com | kubectl apply -f -
endpoints/glusterfs-cluster configured
persistentvolume/gluster-volume-gv0 created
```
