#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

docker build \
    -t flobernd/haproxy-acme-dns01:latest \
    "$SCRIPT_DIR/data"
