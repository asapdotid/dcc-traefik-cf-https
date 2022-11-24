<p align="center">
    <img src="https://i.imgur.com/K7D4zla.png" width="400" />
</p>

# Docker Compose for Traefik + Let’s Encrypt

This guide shows you how to deploy your containers behind Traefik reverse-proxy. It will obtain and refresh HTTPS certificates automatically and it comes with password-protected Traefik dashboard.

## Run on Local Computer

Docker container:

-   Docker Socket Proxy (security) [Document](https://hub.docker.com/r/tecnativa/docker-socket-proxy/#!)
-   Traefik [Document](https://hub.docker.com/_/traefik)
-   Logger (logrotate & cron) `Custom for Alpine`
-   Portainer (Optional) [Document](https://www.portainer.io/)

### Step 1: Make Sure You Have Required Dependencies

-   Git
-   Docker
-   Docker Compose

#### Example Installation on Debian-based Systems:

Official documentation for install Docker with new Docker Compose V2 [doc](https://docs.docker.com/engine/install/), and you can install too Docker Compose V1. Follow official documentation.

```
sudo apt-get install git docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

### Step 2: Clone the Repository

```bash
git clone https://github.com/asapdotid/dcc-traefik.git
cd dcc-traefik
```

or

```bash
git clone git@github.com:wilopo-cargo/dcc-traefik.git
cd dcc-traefik
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

```bash
DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD=1
DOCKER_REGISTRY=docker.io
DOCKER_NAMESPACE=asapdotid
PROJECT_NAME=docker-traefik
ENV=local
TIMEZONE=Asia/Jakarta
```

### Step 3: Make Initial Environment Variables

```bash
make docker-init
```

Modified file in `.docker/.env` for build image

```bash
# docker-compose env vars
# @see https://docs.docker.com/compose/reference/envvars/
COMPOSE_CONVERT_WINDOWS_PATHS=1

# timezone
TIMEZONE=Asia/Jakarta # Timezone for os and log level

# Traefik config
TRAEFIK_LOG_LEVEL=INFO                                                                # Traefik log level: INFO|ERROR|DEBUG
TRAEFIK_DOMAIN_NAME=domain.com                                                        # Domain name
TRAEFIK_DOCKER_NETWORK=proxy                                                          # Docker network
TRAEFIK_DOCKER_ENTRYPOINT=tcp://dockersocket:2375                                     # Docker socket - Don't change
TRAEFIK_ACME_EMAIL_ADDRESS=asapdotid@gmail.com                                        # Acme email (provide valid email)
TRAEFIK_ACME_DNS_CHALLENGE_PROVIDER=cloudflare                                        # Acme Profider
CLOUDFLARE_DNS_API_TOKEN=                                                             # CloudFlare DNS API Token
TRAEFIK_API_DASHBOARD=true                                                            # Traefik Dashboard true|false
TRAEFIK_API_INSECURE=false                                                            # Traefik Insecure Port :8080
TRAEFIK_API_DASHBOARD_SUBDOMAIN=monitor                                               # Traefik Dashboard subdomain monitor.domain.com
TRAEFIK_BASIC_AUTH_USERNAME=admin                                                     # Traefik Dashboard basic auth username
TRAEFIK_BASIC_AUTH_PASSWORD_HASH=JGFwcjEkOVdtNjRHalUkT2dBOEhJNEwxUzYxVXJXbE9aYkNaMQ== # Traefik Dashboard basic auth password encode base64 (read doc)

# Docker compose config
COMPOSE_NETWORK_DRIVER=bridge # Docker network driver
COMPOSE_NETWORK_EXTERNAL=true # Docker network external

# Traefik Ports config
TRAEFIK_HOST_HTTP_PORT=80   # Traefik http port
TRAEFIK_HOST_HTTPS_PORT=443 # Traefik https port

# Docker image version
SOCKET_PROXY_VERSION=0.1
TRAEFIK_VERSION=2.9
ALPINE_VERSION=3.15
```

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

You can paste the username into the `TRAEFIK_USER` environment variable. The other part, `hashedPassword`, should be assigned to `TRAEFIK_PASSWORD_HASH`. Now you have your own `username`:`password` pair.

### Step 5: Launch Your Deployment

Optional create docker network `secure` & `proxy` for external used if integrate with other docker container and `DOCKER_EXTRENAL_NETWORK=true` on environment file:

```bash
make docker-network ARGS="create secure"
```

and

```bash
make docker-network ARGS="create proxy"
```

To do:

```bash
make init

make docker-init

make docker-build

make docker-up / make docker-down
```

### Step 6: Additional Docker Service

-   Whoami
-   Portainer

Can remove or command.

### Step 7: Test Your Deployment

```bash
curl --insecure https://localhost/
```

You can also test it in the browser:

https://localhost/

https://traefik.localhost/

## Deploying on a Public Server With Real Domain

Let's say you have a domain `example.com` and it's DNS records point to your production server. Just repeat the local deployment steps, but don't forget to update `TRAEFIK_DOMAIN_NAME`, `TRAEFIK_ACME_EMAIL_ADDRESS`, `TRAEFIK_ACME_DNS_CHALLENGE_PROVIDER` & `CLOUDFLARE_DNS_API_TOKEN` environment variables. In case of `example.com`, your `.docker/.env` file should have the following lines:

```bash

TRAEFIK_DOMAIN_NAME=example.com
TRAEFIK_ACME_EMAIL_ADDRESS=your@email.com
TRAEFIK_ACME_DNS_CHALLENGE_PROVIDER=letsencrypt
CLOUDFLARE_DNS_API_TOKEN=

```

Setting correct email is important because it allows Let’s Encrypt to contact you in case there are any present and future issues with your certificates.

## Optinonal add `Portainer` service

Uncomment on docker compose file for `Portainer` service:

File: `.docker/compose/docker-compose.local.yml`

```yaml
portainer:
    image: portainer/portainer-ce:latest
    restart: unless-stopped
    security_opt:
        - no-new-privileges:true
    networks:
        - secure
        - proxy
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

Read instruction after container up [instruction](docs/portainer.md)

## License

MIT / BSD

## Author Information

This Docker Compose Traefik was created in 2022 by [Asapdotid](https://github.com/asapdotid) 🚀
