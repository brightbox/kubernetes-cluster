## OpenEBS

[OpenEBS](https://openebs.io) is a Kubernetes Native storage manager that
can create both worker node local Persistent Volumes and replicated
Persistent Volumes that are available to pods across all worker nodes.

### Automatic Installation

Set the `storage_system` variable to `openebs` to install the OpenEBS maangement system and ensure
all the storage partitions are mounted in the correct position.


### Manual Installation

A single command will install the OpenEBS management system within its own `openebs` namespace

```
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

This will create the storage management system within the `openebs` namespaces.

Ensure that the /var/openebs/local directory is avaiable on all the nodes you wish to use for storage.

### After Installation

Once running you can create PersistentVolumeClaims to create the type of storage volume your applications require. 

All volume types supported by OpenEBS mount on a single container at a time using the ReadWriteOnce access mode.

### Default storage class

You can set a default storage class by adding an annotation. For example to use the hostpath Storage Class as default run

``
kubectl annotate sc/openebs-hostpath storageclass.kubernetes.io/is-default-class=true
``
### HostPath Volumes

A Hostpath local PV represents a directory path on the disk of one of the worker volumes. They are dynamically
allocated and operate at full VM disk speed, but offer no replica or snapshot capability. 

The default StorageClass `openebs-hostpath` creates volumes using the
`Delete` Reclaim policy - once the PersistentVolumeClaim is deleted,
the volume is fully deleted.

If you wish to retain the PersistentVolume create a new StorageClass:

```
kubectl get sc/openebs-hostpath -o yaml | sed -e 's/name: openebs-[a-z-]*/&-retain/' -e 's/Delete/Retain/' | kubectl apply -f -
```

and use `openebs-hostpath-retain` as the StorageClass when creating your PVCs.

```
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: demo-vol1-claim
  namespace: default
spec:
  storageClassName: openebs-hostpath-retain
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5G
```

See the [OpenEBS user guide](https://docs.openebs.io/docs/next/uglocalpv.html) for more details on Local PVs and how to
e ackup and restore volumes

### JIRA Volumes

Jiva is a light weight storage engine that is recommended to use for low capacity workloads. It is based on the [Rancher Longhorn](https://rancher.com/blog/2017/announcing-longhorn-microservices-block-storage/) project.

Jiva volumes replicate across worker nodes and the replication is managed by pods on each worker node plus a controller pod to provide access. The result is an iscsi endpoint that can be mounted in a pod from any worker on the cluster.

Jiva will work on standard workers as it just uses a sparse file on the filesystem as the basis for storing the volumes. 

The default StorageClass `openebs-jiva-default` creates volumes using the
`Delete` Reclaim policy - once the PersistentVolumeClaim is deleted,
the volume is fully deleted.

If you wish to retain the PersistentVolume create a new StorageClass:

```
kubectl get sc/openebs-jiva-default -o yaml | sed -e 's/name: openebs-[a-z-]*/&-retain/' -e 's/Delete/Retain/' | kubectl apply -f -
```

and use `openebs-jiva-default-retain` as the StorageClass when creating your PVCs.

```
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: demo-vol1-claim
  namespace: default
spec:
  storageClassName: openebs-jiva-default-retain
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5G
```

See the [OpenEBS user guide](https://docs.openebs.io/docs/next/jivaguide.html) for more details on Jiva Volumes and how to
backup and restore them.


## Examples
### local-statefulset.yaml
This example creates a set of pods that write to the openebs-hostpath Persistent Volumes (PV) on each node.

- apply the set
```
$ kubectl apply -f local-statefulset.yaml
statefulset.apps/local-test created
deployment.extensions/local-test-reader created
```
- check the bindings have all worked as expected
```
$ kubectl get pods
NAME                                 READY     STATUS    RESTARTS   AGE
local-test-0                         1/1       Running   0          34s
local-test-1                         1/1       Running   0          31s
local-test-2                         1/1       Running   0          29s
local-test-reader-56d45cb67f-d66l8   1/1       Running   1          33s
$ kubectl get pvc
NAME                     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS       AGE
local-vol-local-test-0   Bound    pvc-cc04fe59-38b8-4b32-b311-04d2e4d35b52   1Gi        RWO            openebs-hostpath   60s
local-vol-local-test-1   Bound    pvc-4015f95a-fef5-4647-a3f7-8bf90ca4169c   1Gi        RWO            openebs-hostpath   50s
local-vol-local-test-2   Bound    pvc-39ad3669-f7d7-4536-9854-eeb14b927776   1Gi        RWO            openebs-hostpath   36s
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                            STORAGECLASS       REASON   AGE
pvc-39ad3669-f7d7-4536-9854-eeb14b927776   1Gi        RWO            Delete           Bound    default/local-vol-local-test-2   openebs-hostpath            54s
pvc-4015f95a-fef5-4647-a3f7-8bf90ca4169c   1Gi        RWO            Delete           Bound    default/local-vol-local-test-1   openebs-hostpath            65s
pvc-cc04fe59-38b8-4b32-b311-04d2e4d35b52   1Gi        RWO            Delete           Bound    default/local-vol-local-test-0   openebs-hostpath            79s
```
- check that the pods are writing to the persistent volume
```
$ kubectl logs local-test-reader-56d45cb67f-d66l8
Thu Sep 13 16:29:28 UTC 2018
This is local-test-0, count=1
Thu Sep 13 16:29:38 UTC 2018
This is local-test-0, count=1
Thu Sep 13 16:29:48 UTC 2018
This is local-test-0, count=1
Thu Sep 13 16:29:58 UTC 2018
This is local-test-0, count=1
Thu Sep 13 16:30:08 UTC 2018
This is local-test-0, count=1
```
- once you've finished remove the pods
```
$ kubectl delete -f local-statefulset.yaml
statefulset.apps "local-test" deleted
deployment.extensions "local-test-reader" deleted
```
- and strip out the volume claims
```
$ kubectl delete pvc --all
persistentvolumeclaim "local-vol-local-test-0" deleted
persistentvolumeclaim "local-vol-local-test-1" deleted
persistentvolumeclaim "local-vol-local-test-2" deleted
```
- and the pvs are cleaned up automatically
```
$ kubectl get pv
No resources found.
```
