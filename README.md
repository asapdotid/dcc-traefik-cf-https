<p align="center">
    <img src="docs/assets/img/traefik-ssl.png" width="600" />
</p>

# Docker Compose Traefik - Proxy Container Service (Cloudflare)

This guide shows you how to deploy your containers behind Traefik reverse-proxy. It will obtain and refresh `HTTPS` certificates automatically and it comes with password-protected Traefik dashboard.

## Docker container

### Main container

-   Docker Socket Proxy 1.26.2/latest
-   Traefik 2.11.x, 3.1.x, 3.2.x & 3.3.x
-   Logger Alpine Linux 3.20 or 3.21

### Docker container:

-   Docker Socket Proxy (security) - `Linuxserver.io` [Document](https://hub.docker.com/r/linuxserver/socket-proxy)
-   Traefik [Document](https://hub.docker.com/_/traefik)
-   Logger (logrotate & cron) `Custom of Alpine`
-   Portainer (Optional) [Document](https://www.portainer.io/)

### Optional (development)

-   Whoami (prints OS information - local development) [Document](https://github.com/traefik/whoami)
-   Portainer (Optional) [Document](https://www.portainer.io/)

### Step 1: Make Sure You Have Required Dependencies

-   Git
-   Docker
-   Docker Compose

#### Example Installation on Debian-based Systems:

Official documentation for install Docker with new Docker Compose V2 [doc](https://docs.docker.com/engine/install/), and you can install too Docker Compose V1. Follow official documentation.

```bash
sudo apt-get install git docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

### Step 2: Clone the Repository

```bash
git clone https://github.com/asapdotid/dcc-traefik-cf-https.git
cd dcc-traefik-cf-https
```

Make command help:

```bash
make help
```

### Step 3: Make Initial Environment Variables

```bash
make init
```

Modified file in `.make/.env` for build image

```ini
...
# Project variables
DOCKER_REGISTRY=docker.io
DOCKER_NAMESPACE=asapdotid
DOCKER_PROJECT_NAME=tf-proxy

# Docker image version
DOCKER_SOCKET_VERSION=latest
TRAEFIK_VERSION=3.2
ALPINE_VERSION=3.21

# Timezone for os and log level
TIMEZONE=Asia/Jakarta
```

### Step 3: Make Docker Compose Initial Environment Variables

```bash
make env
```

Modified file in `src/.env` for build image

The password is `adminpass` and you might want to change it before deploying to production.

### Step 4: Set Your Own Password

Note: when used in docker-compose.yml all dollar signs in the hash need to be doubled for escaping.

> Install `Apache Tools` package to using `htpasswd`
> To create a `user`:`password` pair, the following command can be used:

```bash
echo $(htpasswd -nb user)

# OR

echo $(htpasswd -nb user password)
```

Running script:

```bash
echo $(htpasswd -nb admin)

New password:
Re-type new password:

admin:$apr1$W3jHMbEG$TCzyOICAWv/6kkraCHKYC0
```

or

```bash
echo $(htpasswd -nb admin adminpass)

admin:$apr1$W3jHMbEG$TCzyOICAWv/6kkraCHKYC0
```

The output has the following format: `username`:`password_hash`. The username doesn't have to be `admin`, feel free to change it (in the first line).

Encode password hash with `base64`:

```bash
echo '$apr1$W3jHMbEG$TCzyOICAWv/6kkraCHKYC0' | openssl enc -e -base64
JGFwcjEkVzNqSE1iRUckVEN6eU9JQ0FXdi82a2tyYUNIS1lDMAo=
```

Check decode:

```bash
echo 'JGFwcjEkVzNqSE1iRUckVEN6eU9JQ0FXdi82a2tyYUNIS1lDMAo=' | openssl enc -d -base64
```

You can paste the username into the `TRAEFIK_BASIC_AUTH_USERNAME` environment variable. The other part, `hashedPassword`, should be assigned to `TRAEFIK_BASIC_AUTH_PASSWORD_HASH`. Now you have your own `username`:`password` pair.

### Step 5: Launch Your Deployment

Optional create docker network `proxy` for external used with other docker containers:

```bash
docker network create proxy
```

```bash
make env

make build
```

Docker composer make commands:

```bash
make up
# or
make down
```

### Step 6: Additional Docker Service

-   Whoami
-   Portainer

Can remove or command.

### Step 7: Test Your Deployment

```bash
curl -I https://{domain_name}/
```

You can also test it in the browser:

https://{domain_name}/

https://monitor.{domain_name}/

# Deploying on a Public Server With Real Domain

Traefik requires you to define "Certificate Resolvers" in the static configuration, which are responsible for retrieving certificates from an ACME server.

Then, each "router" is configured to enable TLS, and is associated to a certificate resolver through the tls.certresolver configuration option.

Read [Traefik Let's Encrypt](https://doc.traefik.io/traefik/https/acme/)

Here is a list of supported providers, on this project:

-   Cloudflare

Let's say you have a domain `example.com` and it's DNS records point to your production server. Just repeat the local deployment steps, but don't forget to update `TRAEFIK_DOMAIN_NAME`, `TRAEFIK_ACME_DNS_CHALLENGE_PROVIDER_EMAIL` & `TRAEFIK_ACME_DNS_CHALLENGE_PROVIDER_TOKEN` environment variables. In case of `example.com`, your `src/.env` file should have the following lines:

```ini
TRAEFIK_DOMAIN_NAME=example.com
TRAEFIK_ACME_DNS_CHALLENGE_PROVIDER_EMAIL=email@mail.com
TRAEFIK_ACME_DNS_CHALLENGE_PROVIDER_TOKEN=coudflare-access-token-123ABC
```

Setting correct email is important because it allows Let’s Encrypt to contact you in case there are any present and future issues with your certificates.

## Redirect `WWW` to `NON WWW` external services (other docker compose file)

Example labels redirect www to npn www:

```yaml
labels:
    - traefik.enable=true
    - traefil.docker.network=proxy
    - traefik.http.routers.whoami.entrypoints=https
    - traefik.http.routers.whoami.rule=Host(`jogjascript.com`)||Host(`www.jogjascript.com`)
    # Add redirect middlewares for http and https
    - traefik.http.routers.whoami.middlewares=redirect-http-www@file,redirect-https-www@file
```

### Example Docker Compose

> File: `src/compose/docker-compose.local.yml`

#### Whoami

```yaml
whoami:
    image: traefik/whoami:latest
    container_name: whoami
    networks:
        - net-internal
    depends_on:
        - traefik
    labels:
        - traefik.enable=true
        - traefik.http.routers.whoami.entrypoints=https
        - traefik.http.routers.whoami.rule=Host(`jogjascript.com`)||Host(`www.jogjascript.com`)
        # Add redirect middlewares for http and https
        - traefik.http.routers.whoami.middlewares=redirect-http-www@file,redirect-https-www@file
```

#### Portainer

```yaml
portainer:
    image: portainer/portainer-ce:latest
    restart: unless-stopped
    security_opt:
        - no-new-privileges:true
    networks:
        - net-internal
    volumes:
        - /etc/localtime:/etc/localtime:ro
        - ../../.data/portainer:/data
    labels:
        - traefik.enable=true
        - traefik.http.routers.portainer.entrypoints=https
        - traefik.http.routers.portainer.rule=Host(`portainer.${TRAEFIK_DOMAIN_NAME}`)
        - traefik.http.services.portainer.loadbalancer.server.port=9000
    depends_on:
        - dockersocket
        - traefik
```

## External Docker Compose Service Integrate with Traefik (`Labels`)

Sample:

```yaml
---
labels:
    - traefik.enable=true
    - traefil.docker.network=proxy
    - traefik.http.routers.portainer.entrypoints=https
    - traefik.http.routers.portainer.rule=Host(`app.${TRAEFIK_DOMAIN_NAME}`)
```

Path prefix with loadbalancer:

```yaml
---
labels:
    - traefik.enable=true
    - traefik.docker.network=proxy
    - traefik.http.routers.backend-v1.entrypoints=https
    - traefik.http.routers.backend-v1.rule=Host(`api.domain_name.com`) && PathPrefix(`/v1`)
    - traefik.http.services.backend-v1.loadbalancer.server.port=3000
    - traefik.http.routers.backend-v1.middlewares=api-strip
    - traefik.http.middlewares.api-strip.stripprefix.prefixes=/v1
```

Sample `nginx` service:

```yaml
---
nginx:
    image: nginx:stable
    networks:
        - proxy
    labels:
        - traefik.enable=true
        - traefil.docker.network=proxy
        - traefik.http.routers.portainer.entrypoints=https
        - traefik.http.routers.portainer.rule=Host(`app.${TRAEFIK_DOMAIN_NAME}`)
```

Also included is an option that allows only TLS v1.3. This option must be manually configured. There is an example below on how to do this with a docker label.

```yaml
---
nginx:
    image: nginx:stable
    networks:
        - proxy
    labels:
        - traefik.enable=true
        - traefil.docker.network=proxy
        # only TLS v1.3
        - traefik.http.routers.project-app.tls.options=tlsv13only@file
        - traefik.http.routers.portainer.entrypoints=https
        - traefik.http.routers.portainer.rule=Host(`app.${TRAEFIK_DOMAIN_NAME}`)
```

Read instruction after container up [instruction](docs/portainer.md)

## License

MIT / BSD

## Author Information

This Docker Compose Traefik HTTPS was created in 2022 by [Asapdotid](https://github.com/asapdotid) 🚀
