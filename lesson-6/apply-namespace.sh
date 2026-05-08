#!/bin/bash
kubectl apply -f ./namespace.yaml
kubectl apply -f ./deployment-namespace.yaml
kubectl get pods -n demo -l run=my-nginx -o wide
