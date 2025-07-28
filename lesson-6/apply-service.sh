#!/bin/bash
kubectl apply -f ./nginx-service.yaml
kubectl get svc my-nginx

#kubectl get services -l run=my-nginx -o wide