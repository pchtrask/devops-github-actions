#!/bin/bash

kubectl get pods -n demo -l run=my-nginx -o wide

# List all namespaces:
# kubectl get namespaces
