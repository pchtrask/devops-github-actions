#!/bin/bash
kubectl apply -f ./nginx-pods.yaml
kubectl get pods -l run=my-nginx -o wide