#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

docker run -it --rm --name haproxy-acme-http01 \
    -v "$SCRIPT_DIR/volume/acme:/var/lib/acme:rw" \
    -e "HAPROXY_HTTP_PORT=80" \
    -e "HAPROXY_HTTPS_PORT=443" \
    -e "ACME_DEBUG=0" \
    -e "ACME_UPGRADE=1" \
    -e "ACME_CROM=1" \
    -e "ACME_MAIL=mail@domain.com" \
    -e "ACME_SERVER=letsencrypt_test" \
    -e "ACME_DOMAIN=domain.com" \
    -e "ACME_KEYLENGTH=ec-256" \
    -e "SERVER_ADDRESS=whoami" \
    -e "SERVER_PORT=80" \
    -e "SERVER_DIRECTIVES=" \
    -p 80:80 \
    -p 443:443 \
    --sysctl net.ipv4.ip_unprivileged_port_start=0 \
    flobernd/haproxy-acme-http01
