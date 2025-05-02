# The Ingress Controller

* Deploy NGINX Ingress Controller:

```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

* Create an Ingress Resource to route traffic to OpenBAO ( <https://kubernetes.io/docs/concepts/services-networking/ingress/#name-based-virtual-hosting> ):

```Yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: openbao-ingress
  namespace: pesto-openbao
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: "openbao.pesto.io"
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: pesto-openbao
            port:
              number: 8200

```

To test it:

```bash
export OPENBAO_PRIVATE_IP_ADDR='172.20.0.5'

curl -i http://${OPENBAO_PRIVATE_IP_ADDR}/ui/ -d Sysdig -H "Host: openbao.pesto.io"

curl -i -L http://${OPENBAO_PRIVATE_IP_ADDR}/ui/ -d Sysdig -H "Host: openbao.pesto.io"


172.20.0.5    openbao.pesto.io
```

I had to restart the cloud-provider-kind external load balancer:

```bash
cd /opt/cloud_provider_kind/run
NET_MODE=kind docker compose up -d

# # ---
# # And I could see the logs with:
# docker-compose -f compose.yaml logs -f
```

## References

* https://kubernetes.github.io/ingress-nginx/examples/rewrite/

## ANNEX


* This one gave me an empty reply from server:

```bash
kubectl --context kind-openbao-cluster -n pesto-openbao port-forward service/pesto-openbao 8201:8201 --address=192.168.1.16
```

* This one gave me the Web UI:

```bash
kubectl --context kind-openbao-cluster -n pesto-openbao port-forward service/pesto-openbao 8200:8200 --address=192.168.1.16
```
