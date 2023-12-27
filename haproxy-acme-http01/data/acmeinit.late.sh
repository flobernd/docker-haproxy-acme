#!/bin/bash
set -e

echo "Waiting for 'haproxy' to respond to ACME challenge requests ..."

until $(curl --output /dev/null --silent --head --fail http://localhost/.well-known/acme-challenge/); do
    sleep 1 & wait $!
done

echo "Issuing certificate for '$ACME_DOMAIN' ..."

result=0
acme.sh --issue -d "$ACME_DOMAIN" --server "$ACME_SERVER" --keylength "$ACME_KEYLENGTH" --stateless || result=$?

if [ $result -ne 0 ] && [ $result -ne 2 ]; then
    # 0 = Certificate issued
    # 2 = Certificate is still valid and does not require renewal
    exit $result
fi

echo "Deploying certificate ..."

export DEPLOY_HAPROXY_HOT_UPDATE=yes
export DEPLOY_HAPROXY_STATS_SOCKET=/var/lib/haproxy/admin.sock
export DEPLOY_HAPROXY_PEM_PATH=/etc/haproxy/certs

acme.sh --deploy -d "$ACME_DOMAIN" --deploy-hook haproxy
