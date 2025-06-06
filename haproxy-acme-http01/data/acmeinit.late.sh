#!/bin/bash
set -e
set -f

echo "Waiting for 'haproxy' to respond to ACME challenge requests ..."

until $(curl --output /dev/null --silent --head --fail http://localhost/.well-known/acme-challenge/); do
    sleep 1 & wait $!
done

echo "Issuing certificate for '$ACME_DOMAIN' ..."

domains=()
for d in $ACME_DOMAIN
do
    domains+=("$d")
done

args=(
    "--issue"
    "--server" "$ACME_SERVER"
    "--keylength" "$ACME_KEYLENGTH"
    "--stateless"
    "-d" "${domains[0]}"
)

for d in "${domains[@]:1}"
do
    args+=("-d" "$d")
done

if [ $ACME_DEBUG -eq 1 ]; then
    args+=("--debug")
fi

result=0
acme.sh "${args[@]}" || result=$?

if [ $result -ne 0 ] && [ $result -ne 2 ]; then
    # 0 = Certificate issued
    # 2 = Certificate is still valid and does not require renewal
    exit $result
fi

echo "Deploying certificate ..."

export DEPLOY_HAPROXY_HOT_UPDATE=yes
export DEPLOY_HAPROXY_STATS_SOCKET=/var/lib/haproxy/admin.sock
export DEPLOY_HAPROXY_PEM_PATH=/etc/haproxy/certs

args=(
    "--deploy"
    "--deploy-hook" "haproxy"
)

for d in "${domains[@]}"
do
    args+=("-d" "$d")
done

acme.sh "${args[@]}"
