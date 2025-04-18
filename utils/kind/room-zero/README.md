# Room Zero

When you provision a Kind Kubernetes Cluster, you can use [Cloud Provider Kind](https://github.com/kubernetes-sigs/cloud-provider-kind), for your deployed Kubernetes Services of type `LoadBalancer` to be assigned an Eternal IP.

Never the less, the IP Address which will be assigned to your deployed Kubernetes Services of type `LoadBalancer`, will not be reachable from outside of the machine where your Kind Kubernetes Cluster runs: This is at least true, if you use a VirtualBox VM, and the network adapter is bound to a wifi network adapter. This is probalby also true in a number o f other cases, if not all.

Room zero is a revrse proxy, provisioned as a docker container, using, docker-compose, which purpose is to expose via a routable IP address, a service of type `LoadBalancer` deployed in a Kind Kubernetes Cluster.

## Usage

* A VM
* the VM has one network adapter bound to a wifi physical netork interface.

```bash
export KND_NET_NAME=${KND_NET_NAME:-'kind'}
export ROOM_ZERO_BIND_ADDR=${ROOM_ZERO_BIND_ADDR:-'0.0.0.0'}
export KND_NET_NAME=${KND_NET_NAME:-'kind'}
export OPENBAO_FQDN=${OPENBAO_FQDN:-"openbao.pesto.io"}
```
