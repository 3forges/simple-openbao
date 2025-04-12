# OpenBAO

## How to provision

### Create Kubernetes Cluster

* Install kind, arkade, kubectl, with scripts, and then run:

```bash
kind create cluster --name openbao-cluster
kubectl cluster-info --context kind-openbao-cluster
kubectl cluster-info --context get all
```

* NEXT: <https://kind.sigs.k8s.io/docs/user/loadbalancer/>

## References

* <https://github.com/kubernetes-sigs/cloud-provider-kind>
* <https://kind.sigs.k8s.io/docs/user/loadbalancer/>