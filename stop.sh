#!/bin/bash

IMAGE_NAME="xuanminator/elk:latest"
CONTAINER_NAME="es1"
DOCKERFILE_PATH="./elk.Dockerfile"
NETWORK_NAME="host"
DOCKERFILE_CONTEXT="."
PERSISTENCE_PATH="./data"
DATA_PATH="/usr/share/elasticsearch/data/indices"

echo "Stopping and deleting container..."
docker stop "$CONTAINER_NAME" && docker container rm "$CONTAINER_NAME"
# docker network rm "$NETWORK_NAME"

echo "If you ever remove the container, you'll have to get the renewed password!"
