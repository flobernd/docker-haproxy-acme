# Docker HAProxy ACME

A Docker image that combines [haproxy](https://www.haproxy.org/) and [acme.sh](https://github.com/acmesh-official/acme.sh).

## Motivation

The combination of `haproxy` and `acme.sh` provides a lightweight alternative to `Traefik` to implement SLL termination for public facing Docker services. A main advantage is the decentralized organization of certificates and the implementation of the Zero Trust principle within a container group.

---

## `haproxy-acme-http01`

The `haproxy-acme-http01` image is a ready-to-run image for local SSL termination and has the following core features:

- HAProxy listening on port `80` and `443`
  - Port `80` is used for the `HTTP-01` ACME certificate challenge and otherwise redirects to `https` by default
  - Port `443` redirects traffic to a configurable `host:port` and provides SSL termination
- Issues a SSL certificate on startup
  - Configurable ACME provider (`Let's Encrypt`, `ZeroSSL`, ...)
  - Configurable key length (`2048`, `4096`, `ec-256`, ...)
  - Supports SAN certificates
- Automatic certificate renewal
  - HAProxy [Hitless Reload](https://www.haproxy.com/blog/hitless-reloads-with-haproxy-howto) (zero downtime)
  - Configurable certificate renewal notifications (WiP)

### Example

```bash
docker run -d --name haproxy-acme-http01 \
    -e "ACME_MAIL=mail@domain.com" \
    -e "ACME_DOMAIN=domain.com" \
    -e "SERVER_ADDRESS=whoami" \
    -e "SERVER_PORT=80" \
    -v /docker_data/acme:/var/lib/acme:rw \
    -p 80:80 \
    -p 443:443 \
    --sysctl net.ipv4.ip_unprivileged_port_start=0 \
    ghcr.io/flobernd/haproxy-acme-http01
```

### Docker Compose Example

```yaml
services:
  haproxy-acme:
    image: ghcr.io/flobernd/haproxy-acme-http01:latest
    container_name: haproxy-acme-http01
    restart: unless-stopped
    environment:
      - ACME_MAIL=mail@domain.com
      - ACME_DOMAIN=domain.com
      - SERVER_ADDRESS=whoami
      - SERVER_PORT=80
    volumes:
      - /docker_data/acme:/var/lib/acme:rw
    ports:
      - 80:80
      - 443:443
    sysctls:
      - net.ipv4.ip_unprivileged_port_start = 0

  whoami:
    image: traefik/whoami
    container_name: whoami
    restart: unless-stopped
```

### Persistence

It is strongly recommended to specify an external volume for the `/var/lib/acme` directory. Most ACME servers enforce a rate limit for issuing and renewing certificates. If you recreate the container without preserving the internal state of `acme.sh`, a new certificate will also be created each time.

### HAProxy Configuration

The container creates a default configuration file `haproxy.cfg` in the `/usr/local/etc/haproxy` directory.

By mapping the aforementioned path, the primary `haproxy.cfg` can be freely customized. Alternatively, additional configurations can be placed in the `include` directory, which are then loaded after the primary configuration in alphabetical order.

As long as the default config has not been modified or overwritten, the `SERVER_ADDRESS` (*required*), `SERVER_PORT` (default `80`), `HAPROXY_HTTP_PORT` (default `80`) and `HAPROXY_HTTPS_PORT` (default `443`) environment variables must be set. Otherwise the container will fail to start.

> [!IMPORTANT]
> When overwriting the default configuration, make sure that the `stats socket` directive is retained. Otherwise, the deployment of certificates will fail.

```
global
  # Allow 'acme.sh' to deploy new certificates without reloading
  stats socket /var/lib/haproxy/admin.sock level admin mode 660
```

> [!IMPORTANT]
> When overwriting the default configuration, make sure that the `http` frontend correctly responds to the `http-01` challenge. Otherwise, the issuing of certificates will fail.

```
frontend http
  mode http
  [...]
  # Respond to ACME HTTP-01 challenge
  http-request return status 200 content-type text/plain lf-string "%[path,field(-1,/)].${ACME_ACCOUNT_THUMBPRINT}\n" if { path_beg '/.well-known/acme-challenge/' }
```

### Environment

#### `ACME_DEBUG`

Set to `1` in order to enable verbose `acme.sh` debug output.

#### `ACME_UPDATE`

Set to `1` in order to automatically update `acme.sh` to the latest version on container startup. This requires an active internet connection (default: `0`).

#### `ACME_CRON`

Set to `1` in order to enable the certificate renewal cronjob (default: `1`).

#### `ACME_SERVER`

The ACME server to use (default: `letsencrypt`).

Supported values: `letsencrypt`, `letsencrypt_test`, `buypass`, `buypass_test`, `zerossl`, `sslcom`, `google`, `googletest` or an explicit ACME server directory URL like e.g. `https://acme-v02.api.letsencrypt.org/directory`

See also: https://github.com/acmesh-official/acme.sh/wiki/Server

#### `ACME_MAIL`

The mail address for the ACME account registration (*required*).

#### `ACME_DOMAIN`

The domain to issue the certificate for (*required*). To issue a multi-domain certificate (SAN), enter additional domains separated by a space character after the primary domain.

For example: `sub.domain.com` (single), `domain.com *.domain.com` (SAN)

#### `ACME_KEYLENGTH`

The desired domain key length (default: `ec-256`).

Supported values (depending on the ACME server capabilities): `2048`, `3072`, `4096`, `8192`, `ec-256`, `ec-384`, `ec-521`.

#### `HAPROXY_HTTP_PORT`

The internal `haproxy` HTTP listening port. Allows changing the internal port to a non-privileged one (default: `80`). Do not forget to adjust the Docker port mapping accordingly (e.g. `-p 80:8080`).

#### `HAPROXY_HTTPS_PORT`

The internal `haproxy` HTTPS listening port. Allows changing the internal port to a non-privileged one (default: `443`). Do not forget to adjust the Docker port mapping accordingly (e.g. `-p 443:8443`).

#### `SERVER_ADDRESS`

The hostname or IP-address of the internal service for which SSL terminiation should be provided (*required*).

#### `SERVER_PORT`

The port of the internal service for which SSL terminiation should be provided (default: `80`).

#### `SERVER_DIRECTIVES`

Optional directives for communicating with the internal service. For example `ssl` must be specified here, if the internal service uses HTTPS. Check the `haproxy` documentation for more directives.

---

## `haproxy-acme-dns01`

The `haproxy-acme-dns01` image is a ready-to-run image for local SSL termination and has the following core features:

- Issues a SSL certificate on startup
  - Configurable ACME provider (`Let's Encrypt`, `ZeroSSL`, ...)
  - Configurable key length (`2048`, `4096`, `ec-256`, ...)
  - Supports SAN certificates
  - Supports wildcard certificates
- Automatic certificate renewal
  - HAProxy [Hitless Reload](https://www.haproxy.com/blog/hitless-reloads-with-haproxy-howto) (zero downtime)
  - Configurable certificate renewal notifications (WiP)

### Example

```bash
docker run -d --name haproxy-acme-dns01 \
    -e "ACME_MAIL=mail@domain.com" \
    -e "ACME_DOMAIN=domain.com *.domain.com" \
    -e "ACME_DNS_API=dns_cf" \
    -e "CF_Token=<redacted>" \
    -e "CF_Zone_ID=<redacted>" \
    -v /docker_data/acme:/var/lib/acme:rw \
    -p 80:80 \
    -p 443:443 \
    ghcr.io/flobernd/haproxy-acme-dns01
```

### Docker Compose Example

```yaml
services:
  haproxy-acme:
    image: ghcr.io/flobernd/haproxy-acme-dns01:latest
    container_name: haproxy-acme-dns01
    restart: unless-stopped
    environment:
      - "ACME_MAIL=mail@domain.com"
      - "ACME_DOMAIN=domain.com *.domain.com"
      - "ACME_DNS_API=dns_cf"
      - "CF_Token=<redacted>"
      - "CF_Zone_ID=<redacted>"
    volumes:
      - /docker_data/acme:/var/lib/acme:rw
    ports:
      - 80:80
      - 43:443
```

### Persistence

It is strongly recommended to specify an external volume for the `/var/lib/acme` directory. Most ACME servers enforce a rate limit for issuing and renewing certificates. If you recreate the container without preserving the internal state of `acme.sh`, a new certificate will also be created each time.

### HAProxy Configuration

The container creates a default configuration file `haproxy.cfg` in the `/usr/local/etc/haproxy` directory.

By mapping the aforementioned path, the primary `haproxy.cfg` can be freely customized. Alternatively, additional configurations can be placed in the `include` directory, which are then loaded after the primary configuration in alphabetical order.

As long as the default config has not been modified or overwritten, the `SERVER_ADDRESS` (*required*), `SERVER_PORT` (default `80`), `HAPROXY_HTTP_PORT` (default `80`) and `HAPROXY_HTTPS_PORT` (default `443`) environment variables must be set. Otherwise the container will fail to start.

> [!IMPORTANT]
> When overwriting the default configuration, make sure that the `stats socket` directive is retained. Otherwise, the deployment of certificates will fail.

```
global
  # Allow 'acme.sh' to deploy new certificates without reloading
  stats socket /var/lib/haproxy/admin.sock level admin mode 660
```

### Environment

#### `ACME_DEBUG`

Set to `1` in order to enable verbose `acme.sh` debug output.

#### `ACME_UPDATE`

Set to `1` in order to automatically update `acme.sh` to the latest version on container startup. This requires an active internet connection (default: `0`).

#### `ACME_CRON`

Set to `1` in order to enable the certificate renewal cronjob (default: `1`).

#### `ACME_SERVER`

The ACME server to use (default: `letsencrypt`).

Supported values: `letsencrypt`, `letsencrypt_test`, `buypass`, `buypass_test`, `zerossl`, `sslcom`, `google`, `googletest` or an explicit ACME server directory URL like e.g. `https://acme-v02.api.letsencrypt.org/directory`

See also: https://github.com/acmesh-official/acme.sh/wiki/Server

#### `ACME_MAIL`

The mail address for the ACME account registration (*required*).

#### `ACME_DOMAIN`

The domain to issue the certificate for (*required*). To issue a multi-domain certificate (SAN), enter additional domains separated by a space character after the primary domain.

For example: `sub.domain.com` (single), `domain.com *.domain.com` (SAN)

#### `ACME_KEYLENGTH`

The desired domain key length (default: `ec-256`).

Supported values (depending on the ACME server capabilities): `2048`, `3072`, `4096`, `8192`, `ec-256`, `ec-384`, `ec-521`.

#### `ACME_DNS_API`

The DNS API to use (*required*).

Supported values (incomplete): `dns_cf` (Cloudflare), `dns_azure` (Azure), `dns_gcloud` (Google Cloud), ...

Depending on the DNS API, additional environment variables must be passed to the container. For example, `dns_cf` requires the `CF_Token` and `CF_Zone_ID`/`CF_Account_ID` environment variables to be set.

See also: https://github.com/acmesh-official/acme.sh/wiki/dnsapi

#### `ACME_DNS_SLEEP`

The time in seconds to wait for all the TXT records to propagate in DNS API mode. It's not necessary to use this by default, `acme.sh` polls DNS status by DOH automatically.

#### `HAPROXY_HTTP_PORT`

The internal `haproxy` HTTP listening port. Allows changing the internal port to a non-privileged one (default: `80`). Do not forget to adjust the Docker port mapping accordingly (e.g. `-p 80:8080`).

#### `HAPROXY_HTTPS_PORT`

The internal `haproxy` HTTPS listening port. Allows changing the internal port to a non-privileged one (default: `443`). Do not forget to adjust the Docker port mapping accordingly (e.g. `-p 443:8443`).

#### `SERVER_ADDRESS`

The hostname or IP-address of the internal service for which SSL terminiation should be provided (*required*).

#### `SERVER_PORT`

The port of the internal service for which SSL terminiation should be provided (default: `80`).

#### `SERVER_DIRECTIVES`

Optional directives for communicating with the internal service. For example `ssl` must be specified here, if the internal service uses HTTPS. Check the `haproxy` documentation for more directives.

---

## `haproxy-acme`

The base image `haproxy-acme` is based on the [Docker "Official Image"](https://github.com/docker-library/haproxy) for [haproxy](https://www.haproxy.org/) and the [acme.sh](https://github.com/acmesh-official/acme.sh) Bash script. It serves as a generic template, providing some hook points for customization:

#### `/usr/local/bin/acmeinit.early.sh`

This script is executed before `haproxy` starts. Environment variables exported by this script can be used in the `haproxy` configuration file.

#### `/usr/local/bin/acmeinit.late.sh`

This script is executed after `haproxy` started.

#### `/usr/local/bin/initialize.sh`

This script is executed as `root` before switching to the `haproxy` user context.

#### `/usr/local/etc/haproxy`

The default location of the main `haproxy` configuration file `haproxy.cfg` and the `includes` directory.

---

## License

Docker HAProxy ACME is licensed under the MIT license.
