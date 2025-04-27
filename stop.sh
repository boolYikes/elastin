#!/bin/bash

IMAGE_NAME="xuanminator/elk:latest"
CONTAINER_NAME="es1"
DOCKERFILE_PATH="./elk.Dockerfile"
NETWORK_NAME="elastic"
DOCKERFILE_CONTEXT="."

docker stop "$CONTAINER_NAME"
docker container rm "$CONTAINER_NAME"
docker network rm "$NETWORK_NAME"

echo "If you ever remove the container, you'll have to get the renewed password!"