#!/bin/bash

ns="${NAMESPACE:-locust-operator}"

secret=$(kubectl get --namespace "$ns" secret -o json | jq -rc '.items[] | select(.metadata.name | startswith("default-dockercfg")).metadata.name')

kubectl patch --namespace "$ns" secret $secret --type=merge -p '{"data": {".dockercfg" :"'$(kubectl get --namespace "$ns" secret $secret -o json | jq -r '.data | map_values(@base64d).".dockercfg"' | jq -rc '."https://index.docker.io/v1/".auth = "'${TOKEN}'"' | base64 -w0)'"}}'
