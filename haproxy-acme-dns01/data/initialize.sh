#!/bin/bash
set -e

# Adjust permissions for 'haproxy' certificate directory

mkdir -p /etc/haproxy/certs
chown -R haproxy:haproxy /etc/haproxy/certs
chmod 0700 /etc/haproxy/certs
chmod 0600 /etc/haproxy/certs/* 2> /dev/null || true

# Copy 'haproxy' configuration template

haproxy_cfg_template=/etc/haproxy/haproxy.cfg.template
haproxy_cfg=/usr/local/etc/haproxy/haproxy.cfg
if [ ! -f "$haproxy_cfg" ]; then
    cp "$haproxy_cfg_template" "$haproxy_cfg"
    chown haproxy:haproxy "$haproxy_cfg"
    chmod 0600 "$haproxy_cfg"
fi

# Check mandatory environment variables

mandatory=(
    "ACME_SERVER"
    "ACME_MAIL"
    "ACME_DOMAIN"
    "ACME_KEYLENGTH"
    "ACME_DNS_API"
)

if cmp -s "$haproxy_cfg" "$haproxy_cfg_template"; then
    mandatory+=(
        "HAPROXY_HTTP_PORT"
        "HAPROXY_HTTPS_PORT"
        "SERVER_ADDRESS"
        "SERVER_PORT"
    )
fi

missing=false
for value in "${mandatory[@]}"
do
    if [ -z "${!value}" ]; then
        missing=true
        echo "Missing mandatory environment variable: '$value'"
    fi
done

if [ "$missing" = true ]; then
    exit 1
fi
