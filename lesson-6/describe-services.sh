#!/bin/bash


kubectl describe svc my-nginx

kubectl get endpointslices -l kubernetes.io/service-name=my-nginx
