#!/bin/bash

docker run -it --rm --name haproxy-acme \
    -v ./volume/acme:/var/lib/acme:rw \
    --sysctl net.ipv4.ip_unprivileged_port_start=0 \
    flobernd/haproxy-acme \
    /bin/bash
