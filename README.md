# OpenBAO

## How to provision

### Create Kubernetes Cluster

* Install kind, arkade, kubectl, with scripts, and then run:

```bash
kind create cluster --name openbao-cluster
kubectl cluster-info --context kind-openbao-cluster
kubectl --context kind-openbao-cluster get all
```

* NEXT: <https://kind.sigs.k8s.io/docs/user/loadbalancer/>

```bash

chmod +x ./utils/kind/cloud-provider-kind/provision.cloud.provider.sh

./utils/kind/cloud-provider-kind/provision.cloud.provider.sh

kubectl --context kind-openbao-cluster apply -f ./utils/kind/cloud-provider-kind/example.yaml

kubectl --context kind-openbao-cluster get all
```

Now it works and the load balancer assigns addresses on a docker network (below the `172.20.0.4` ip address):

![cloud provider works](./docs/cloud-provider-now-works.PNG)

So now all I need to find out, is how to hit the `172.20.0.4` from outside of the VM. A few tests cofirmed that the best way to do that is a reverse proxy:

NEXT TODO: an ansible playbook to provision the whole stack properly, with a `recreate` option to recreate all from scratch.
