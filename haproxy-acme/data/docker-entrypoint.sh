#!/bin/bash
set -e

if [ "$1" = 'daemon' ]; then
    # Grant 'supervisor' write access to '/dev/stdout' and '/dev/stderr'
    chmod o+w /dev/stdout
    chmod o+w /dev/stderr

    # Adjust permissions for 'acme' config directory
    chown -R haproxy:haproxy /var/lib/acme
    chmod 0700 /var/lib/acme

    # Adjust permissions for 'haproxy' directories
    chown -R haproxy:haproxy /usr/local/etc/haproxy
    chmod 0700 /usr/local/etc/haproxy
    chmod 0600 /usr/local/etc/haproxy/* 2> /dev/null || true

    mkdir -p /usr/local/etc/haproxy/include
    chown -R haproxy:haproxy /usr/local/etc/haproxy/include
    chmod 0700 /usr/local/etc/haproxy/include
    chmod 0600 /usr/local/etc/haproxy/include/* 2> /dev/null || true

    # Source the 'acme.sh' alias
    source /usr/local/share/acme/acme.sh.env

    # Upgrade 'acme.sh'
    if [ $ACME_UPGRADE -eq 1 ]; then
        acme.sh --upgrade
        chown -R haproxy:haproxy /var/lib/acme
    fi

    # Run custom initialization script
    /usr/local/bin/initialize.sh

    # We do not want to use '--reset-env' in order to preserve the Docker environment variables.
    # Manually initialize some variables for the 'haproxy' user:
    export LOGNAME=haproxy
    export USER=haproxy
    export HOME=/var/lib/haproxy
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    export SHELL=/bin/bash

    # Execute bootstrap script on behalf of the 'haproxy' user
    exec setpriv --reuid=haproxy --regid=haproxy --init-groups "/usr/local/bin/bootstrap.sh"
fi

if [ "${1#-}" != "$1" ]; then
    set -- haproxy "$@"
fi

if [ "$1" = 'haproxy' ]; then
    shift
    set -- haproxy -W -db "$@"
fi

# Execute custom command on behalf of the 'haproxy' user
exec setpriv --reuid=haproxy --regid=haproxy --init-groups --reset-env "$@"
