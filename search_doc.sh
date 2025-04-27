#!/bin/bash

PASSWORD=$(cat ./pw.env)

# To use request body, use _search endpoint, not _doc
curl --cacert http_ca.crt -u elastic:"$PASSWORD" -X GET "https://localhost:9200/test-index/_search" \
    -H "Content-Type: application/json" \
    -d '{"query": {"match": {"name": "Babo"}}}' | tee ./result.json

echo -e "\n"