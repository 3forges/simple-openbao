#!/bin/bash

# https://openbao.org/docs/platform/k8s/helm/

helm repo add openbao https://openbao.github.io/openbao-helm

helm search repo openbao/openbao -l

export DESIRED_CHART_VERSION=${DESIRED_CHART_VERSION:-'0.12.0'}

export HELM_KUBECONTEXT=${HELM_KUBECONTEXT:-'kind-openbao-cluster'}


export HELM_RELEASE_NAME=${HELM_RELEASE_NAME:-'pesto-openbao'}
export K8S_NS=${K8S_NS:-'pesto-openbao'}


helm install ${HELM_RELEASE_NAME} openbao/openbao --version ${DESIRED_CHART_VERSION} \
     --namespace ${K8S_NS} \
     --create-namespace \
     --set server.dev.enabled=true


# helm delete ${HELM_RELEASE_NAME}

helm get manifest -n ${K8S_NS} ${HELM_RELEASE_NAME}
helm status -n ${K8S_NS} ${HELM_RELEASE_NAME}

kubectl --context kind-openbao-cluster get all -n pesto-openbao
