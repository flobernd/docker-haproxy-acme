ARG BASE_IMAGE=flobernd/haproxy-acme:latest

FROM $BASE_IMAGE

# Environment

ENV HAPROXY_HTTP_PORT=80
ENV HAPROXY_HTTPS_PORT=443

ENV ACME_SERVER=letsencrypt
ENV ACME_MAIL=
ENV ACME_DOMAIN=
ENV ACME_KEYLENGTH=ec-256
ENV ACME_DNS_API=
ENV ACME_DNS_SLEEP=

ENV SERVER_ADDRESS=
ENV SERVER_PORT=80
ENV SERVER_DIRECTIVES=

# Set up 'haproxy' certificate directory

RUN mkdir -p /etc/haproxy/certs && chown haproxy:haproxy /etc/haproxy/certs && chmod 0700 /etc/haproxy/certs

# Copy 'haproxy' configuration template

COPY --chown=haproxy:haproxy ./haproxy.cfg /etc/haproxy/haproxy.cfg.template

# Copy scripts

COPY acmeinit.early.sh /usr/local/bin/
COPY acmeinit.late.sh  /usr/local/bin/
COPY initialize.sh     /usr/local/bin/
