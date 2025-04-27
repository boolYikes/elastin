#!/bin/bash

PASSWORD=$(cat ./pw.env)

# To use query param, use _doc endpoint with an id
curl --cacert http_ca.crt -u elastic:"$PASSWORD" -X GET "https://localhost:9200/test-index/_doc/1" \
    -H "Content-Type: application/json"

echo -e "\n"