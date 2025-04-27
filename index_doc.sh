#!/bin/bash

PASSWORD=$(cat ./pw.env)

curl --cacert http_ca.crt -u elastic:"$PASSWORD" -X POST "https://localhost:9200/test-index/_doc/1" \
    -H "Content-Type: application/json" \
    -d '{"name": "Babo", "age": 30, "city": "Wonderland"}' | tee ./result.json

echo -e "\n"