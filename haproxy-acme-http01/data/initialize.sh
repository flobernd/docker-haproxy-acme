#!/bin/bash
set -e

if [ -z "$ACME_SERVER" ] ||  \
   [ -z "$ACME_MAIL" ] ||  \
   [ -z "$ACME_DOMAIN" ] ||  \
   [ -z "$ACME_KEYLENGTH" ] || \
   [ -z "$HAPROXY_HTTP_PORT" ] || \
   [ -z "$HAPROXY_HTTPS_PORT" ] ||  \
   [ -z "$SERVER_ADDRESS" ] || \
   [ -z "$SERVER_PORT" ];
then
    echo "Missing mandatory environment variables:"
    echo "  ACME_SERVER        (current: '$ACME_SERVER')"
    echo "  ACME_MAIL          (current: '$ACME_MAIL')"
    echo "  ACME_DOMAIN        (current: '$ACME_DOMAIN')"
    echo "  ACME_KEYLENGTH     (current: '$ACME_KEYLENGTH')"
    echo "  HAPROXY_HTTP_PORT  (current: '$HAPROXY_HTTP_PORT')"
    echo "  HAPROXY_HTTPS_PORT (current: '$HAPROXY_HTTPS_PORT')"
    echo "  SERVER_ADDRESS     (current: '$SERVER_ADDRESS')"
    echo "  SERVER_PORT        (current: '$SERVER_PORT')"
    exit 1
fi

# TODO: Make this behavior configurable

chown -R haproxy:haproxy /etc/haproxy/certs
chmod 0700 /etc/haproxy/certs
chmod 0600 /etc/haproxy/certs/* 2> /dev/null || true
