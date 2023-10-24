#!/bin/bash

secret=$(oc get secrets -o json | jq -rc '.items[] | select(.metadata.name | startswith("default-dockercfg")).metadata.name')

oc patch secret $secret --type=merge -p '{"data": {".dockercfg" :"'$(oc get secret $secret -o json | jq -r '.data | map_values(@base64d).".dockercfg"' | jq -rc '."https://index.docker.io/v1/".auth = "'${TOKEN}'"' | base64 -w0)'"}}'
