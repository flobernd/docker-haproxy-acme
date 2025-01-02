#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

docker run -it --rm --name haproxy-acme-tlsalpn01 \
    -v "$SCRIPT_DIR/volume/acme:/var/lib/acme:rw" \
    flobernd/haproxy-acme-tlsalpn01 \
    /bin/bash
