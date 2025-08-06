#!/bin/bash

cd "$(dirname "$0")/docker"
docker build -t mynginx:latest .

docker tag mynginx:latest 739133790707.dkr.ecr.eu-central-1.amazonaws.com/mynginx:latest
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 739133790707.dkr.ecr.eu-central-1.amazonaws.com
docker push 739133790707.dkr.ecr.eu-central-1.amazonaws.com/mynginx:latest