#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

docker build \
    -t flobernd/haproxy-acme:latest \
    "$SCRIPT_DIR/haproxy-acme/data"

docker build \
    -t flobernd/haproxy-acme-http01:latest \
    "$SCRIPT_DIR/haproxy-acme-http01/data"
