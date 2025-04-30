#!/bin/bash

IMAGE_NAME="xuanminator/elk:latest"
CONTAINER_NAME="es1"
DOCKERFILE_PATH="./elk.Dockerfile"
NETWORK_NAME="host"
DOCKERFILE_CONTEXT="."
CERT_PATH="/usr/share/elasticsearch/config/certs/http_ca.crt"
TARGET_PROJECT="/lab/dee/repos_side/radeeo/airflow/services"
PERSISTENCE_PATH="./data/indices"
DATA_PATH="/usr/share/elasticsearch/data"

# Add back in the commented out parts if using other network name

#if ! docker network inspect "$NETWORK_NAME" > /dev/null 2>&1; then
#    echo "Creating the network..."
#    docker network create "$NETWORK_NAME"
#fi

if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
    echo "No image found. building..."
    docker build -f "$DOCKERFILE_PATH" -t "$IMAGE_NAME" "$DOCKERFILE_CONTEXT" || {
        echo "Build failed"
#        docker network rm "$NETWORK_NAME"
        exit 1
    }
else
    echo "Image exists."
fi

container_status=$(docker ps -a --filter "name=^/${CONTAINER_NAME}$" --format "{{.Status}}")

# Single node ELS can't take a volume or it will give you discovery & tls related errors.
# Just for testing purposes, we'll put up with that
if [ -z "$container_status" ]; then
    echo "Container '$CONTAINER_NAME' does not exist. Creating and starting..."
    docker run --name "$CONTAINER_NAME" --net "$NETWORK_NAME" \
	-p 9200:9200 -dt -m 1GB "$IMAGE_NAME"
elif [[ "$container_status" == Exited* ]]; then
    echo "There's an old stopped container. Restarting..."
    docker container rm "$CONTAINER_NAME"
    docker run --name "$CONTAINER_NAME" --net "$NETWORK_NAME" \
	-p 9200:9200 -dt -m 1GB "$IMAGE_NAME"
else
    echo "Container is already running..."
fi

# Check for ca cert
while true; do
    if docker exec "$CONTAINER_NAME" test -f "$CERT_PATH"; then
        echo "Cert exists, fetching..."
        docker cp "$CONTAINER_NAME":"$CERT_PATH" .
	cp ./http_ca.crt "$TARGET_PROJECT"/http_ca.crt
        break
    else
        echo "Cert does not exist. Init may not have finished yet. Polling..."
        sleep 5
    fi
done

# We can just use the initial pw
# docker exec -it "$CONTAINER_NAME" /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic
command="docker logs es1 | grep -A 1 Password | tail -n 1 | sed 's/\x1b\[[0-9;]*m//g'"
while true; do
    result=$(eval "$command")

    trimmed=$(echo "$result" | sed -e 's/^[[:space:]\n]*//' -e 's/[[:space:]\n]*$//')

    if [ -n "$trimmed" ]; then
        echo "Found password. Fetching..."
        echo "$trimmed" > ./pw.env
	sed -i "s/^ELS_PW=.*/ELS_PW=${trimmed}/" "$TARGET_PROJECT"/.env
	sed -i "s/^ELS_PW=.*/ELS_PW=${trimmed}/" $(pwd)/.env
        break
    else
        echo "Password section empty. Could be still initializing. Polling..."
        sleep 5
    fi
done
echo "PW copied to pw.env"

# motd on startup
curl --cacert http_ca.crt -u elastic:$(cat ./pw.env) https://localhost:9200
