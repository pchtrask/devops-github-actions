#!/bin/bash

kubectl get pods -l run=my-nginx -o wide
kubectl get pods -l run=my-nginx -o custom-columns=POD_IP:.status.podIPs


# kubectl exec my-nginx-77b9c67898-7nvnd -- printenv | grep SERVICE