<p align="center">
    <img src="https://i.imgur.com/K7D4zla.png" width="400" />
</p>

# Docker Compose for Traefik + Let’s Encrypt

This guide shows you how to deploy your containers behind Traefik reverse-proxy. It will obtain and refresh HTTPS certificates automatically and it comes with password-protected Traefik dashboard.

## Testing on Your Local Computer

### Step 1: Make Sure You Have Required Dependencies

-   Git
-   Docker
-   Docker Compose

#### Example Installation on Debian-based Systems:

Official documentation for install Docker with new Docker Compose V2 [doc](https://docs.docker.com/engine/install/), and you can install too Docker Compose V1. Follow official documentation.

```
sudo apt install git docker-ce docker-ce-cli containerd.io docker-compose-plugin
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

### Step 3: Add Environment Variables

```bash
nano .env
```

```bash
DOMAIN=localhost
EMAIL=admin@localhost
CERT_RESOLVER=
TRAEFIK_USER=admin
TRAEFIK_PASSWORD_HASH=$$apr1$$iLM9/PfE$$UqunvjJkWeyqzal.uwwOD0
```

Note that you should leave `CERT_RESOLVER` variable empty if you test your deployment locally. The password is `admin` and you might want to change it before deploying to production.

### Step 4: Set Your Own Password

Note: when used in docker-compose.yml all dollar signs in the hash need to be doubled for escaping.

> Install `Apache Tools` package to using `htpasswd`
> To create a `user`:`password` pair, the following command can be used:

```bash
echo $(htpasswd -nb user) | sed -e s/\\$/\\$\\$/g

# OR

echo $(htpasswd -nb user password) | sed -e s/\\$/\\$\\$/g
```

Running script:

```bash
echo $(htpasswd -nb admin) | sed -e s/\\$/\\$\\$/g

New password:
Re-type new password:

admin:$$apr1$$AfVHQxzp$$WDjX6WDlgGNRHLgdrjSA20
```

or

```bash
echo $(htpasswd -nb admin adminpass) | sed -e s/\\$/\\$\\$/g

admin:$$apr1$$AfVHQxzp$$WDjX6WDlgGNRHLgdrjSA20
```

The output has the following format: `username`:`password_hash`. The username doesn't have to be `admin`, feel free to change it (in the first line).

You can paste the username into the `TRAEFIK_USER` environment variable. The other part, `hashedPassword`, should be assigned to `TRAEFIK_PASSWORD_HASH`. Now you have your own `username`:`password` pair.

### Step 5: Launch Your Deployment

Optional create docker network `proxy` for external used if integrate with other docker container and `DOCKER_EXTRENAL_NETWORK=true` on environment file:

```bash
docker network create proxy
```

To do:

```bash
sudo docker-compose up -d
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

Let's say you have a domain `example.com` and it's DNS records point to your production server. Just repeat the local deployment steps, but don't forget to update `DOMAIN`, `EMAIL` and `CERT_RESOLVER` environment variables. In case of `example.com`, your `.env` file should have the following lines:

```bash
DOMAIN=example.com
EMAIL=your@email.com
CERT_RESOLVER=letsencrypt
```

Setting correct email is important because it allows Let’s Encrypt to contact you in case there are any present and future issues with your certificates.

## License

MIT / BSD

## Author Information

This Docker Compose Traefik was created in 2022 by [Asapdotid](https://github.com/asapdotid) for [Wilopo Crago](https://wilopocargo.com/)
