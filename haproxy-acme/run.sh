#!/bin/bash

docker run -it --rm --name haproxy-acme \
    -v ./volume/acme:/var/lib/acme:rw \
    -e "HAPROXY_HTTP_PORT=80" \
    -e "HAPROXY_HTTPS_PORT=443" \
    -e "ACME_UPGRADE=1" \
    -e "ACME_MAIL=a@b.de" \
    -e "ACME_SERVER=zerossl" \
    -e "ACME_DOMAIN=test.flobernd.de" \
    -e "ACME_KEYLENGTH=ec-256" \
    -e "SERVER_ADDRESS=whoami" \
    -e "SERVER_PORT=80" \
    -e "SERVER_DIRECTIVES=" \
    -p 80:80 \
    -p 443:443 \
    --sysctl net.ipv4.ip_unprivileged_port_start=0 \
    flobernd/haproxy-acme
