ARG BASE_IMAGE=haproxy:bookworm

FROM $BASE_IMAGE

# Environment

ENV ACME_DEBUG=0
ENV ACME_UPDATE=0
ENV ACME_CRON=1

# Reset user to root

USER root

# Restore default workdir and stop-signal

WORKDIR /
STOPSIGNAL SIGTERM

# Install 'acme.sh'

RUN set -eux; \
    \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
    ; \
    \
    mkdir /usr/local/share/acme/; \
    \
    git clone https://github.com/acmesh-official/acme.sh.git && \
    mkdir -p /var/lib/acme && chown haproxy:haproxy /var/lib/acme && chmod 0600 /var/lib/acme &&  \
    cd acme.sh/ && \
    ./acme.sh \
        --install \
        --no-cron \
        --no-profile \
        --home /usr/local/share/acme/ \
        --config-home /var/lib/acme/ && \
    cd .. && \
    rm -rf ./acme.sh/ && \
    chown -R haproxy:haproxy /var/lib/acme && \
    ln -s /usr/local/share/acme/acme.sh /usr/local/bin/ && \
    chmod 755 /usr/local/share/acme/; \
    \
    apt-mark auto '.*' > /dev/null; \
    [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
    find /usr/local -type f -executable -exec ldd '{}' ';' \
        | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
        | sort -u \
        | xargs -r dpkg-query --search \
        | cut -d: -f1 \
        | sort -u \
        | xargs -r apt-mark manual \
    ; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

# Create 'acme.sh' alias for 'haproxy' user

RUN echo 'export LE_WORKING_DIR="/usr/local/share/acme"\n\
export LE_CONFIG_HOME="/var/lib/acme"\n\
alias acme.sh="/usr/local/share/acme/acme.sh --config-home '"'"'/var/lib/acme'"'"'"\n' > /usr/local/share/acme/acme.sh.env

RUN echo '. "/usr/local/share/acme/acme.sh.env"' >> /var/lib/haproxy/.bashrc && \
    chown haproxy:haproxy /var/lib/haproxy/.bashrc && \
    chmod 0644 /var/lib/haproxy/.bashrc

# Install 'supervisord' and 'acme.sh' dependencies

RUN apt-get install -y --no-install-recommends \
        supervisor \
        ca-certificates \
        curl \
        socat \
        idn

COPY --chown=haproxy:haproxy supervisord.conf /etc/supervisord.conf

# Set up 'haproxy' config directories

RUN mkdir -p /etc/haproxy && chown haproxy:haproxy /etc/haproxy && chmod 0700 /etc/haproxy
RUN mkdir -p /usr/etc/haproxy/include && chown haproxy:haproxy /usr/etc/haproxy/include && chmod 0700 /usr/etc/haproxy/include

# Copy scripts

COPY acmeinit.early.sh /usr/local/bin/
COPY acmeinit.late.sh  /usr/local/bin/
COPY bootstrap.sh      /usr/local/bin/
COPY cron.sh           /usr/local/bin/
COPY initialize.sh     /usr/local/bin/

# Cleanup

RUN rm -rf /var/lib/apt/lists/*

# Smoke test
RUN haproxy -v

# Replace source image entrypoint and command

COPY docker-entrypoint.sh /usr/local/bin/
CMD ["daemon"]
