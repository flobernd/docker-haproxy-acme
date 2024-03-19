#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

docker run -it --rm --name haproxy-acme \
    -v "$SCRIPT_DIR/volume/acme:/var/lib/acme:rw" \
    -e "ACME_DEBUG=0" \
    -e "ACME_UPGRADE=1" \
    -e "ACME_CRON=1" \
    flobernd/haproxy-acme
