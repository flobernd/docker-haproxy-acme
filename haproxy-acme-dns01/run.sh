#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

docker run -it --rm --name haproxy-acme-dns01 \
    -v "$SCRIPT_DIR/volume/acme:/var/lib/acme:rw" \
    -e "HAPROXY_HTTP_PORT=80" \
    -e "HAPROXY_HTTPS_PORT=443" \
    -e "ACME_DEBUG=0" \
    -e "ACME_UPGRADE=1" \
    -e "ACME_CRON=1" \
    -e "ACME_MAIL=mail@domain.com" \
    -e "ACME_SERVER=letsencrypt_test" \
    -e "ACME_DOMAIN=domain.com *.domain.com" \
    -e "ACME_KEYLENGTH=ec-256" \
    -e "ACME_DNS_API=dns_cf" \
    -e "ACME_DNS_SLEEP=30" \
    -e "CF_Token=<redacted>" \
    -e "CF_Zone_ID=<redacted>" \
    -p 80:80 \
    -p 443:443 \
    --sysctl net.ipv4.ip_unprivileged_port_start=0 \
    flobernd/haproxy-acme-dns01
