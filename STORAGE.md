# Adding Storage Options to a Kubernetes Cluster

Once you have a built a cluster you will want to add a storage manager
to handle any persistent storage you have available on your worker nodes.

## OpenEBS

OpenEBS(https://openebs.io) is a Kubernetes Native storage manager that
can create both worker node local Persistent Volumes and replicated
Persistent Volumes that are availalbe to pods across all worker nodes.

### Installation

A single command will install the OpenEBS management system within its own `openebs` namespace

```
kubectl apply -f https://openebs.github.io/charts/openebs-operator-1.0.0.yaml
```

This will create the storage management system within the `openebs` namespaces. Once running
you can create PersistentVolumeClaims to create the type of storage volume your applications require. 

All volume types supported by OpenEBS mount on a single container at a time using the ReadWriteOnce access mode.

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
backup and restore volumes

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

