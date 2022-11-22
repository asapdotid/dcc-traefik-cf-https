#!/bin/sh

TRAEFIK_CONFIG_FILE=/etc/traefik/traefik.yml
TRAEFIK_DYNAMIC_CONFIG_FILE=/etc/traefik/conf/dynamic.yml

# Modify traefik config
if [[ -f "TRAEFIK_CONFIG_FILE" ]]; then
  sed -i /etc/traefik/traefik.yml \
    -e "s#__LOG_LEVEL#$TRAEFIK_LOG_LEVEL#g" \
    -e "s#__TRAEFIK_API_DASHBOARD#$TRAEFIK_API_DASHBOARD#g" \
    -e "s#__TRAEFIK_API_INSECURE#$TRAEFIK_API_INSECURE#g" \
    -e "s#__DOMAIN_NAME#$TRAEFIK_DOMAIN_NAME#g" \
    -e "s#__DOCKER_NETWORK#$TRAEFIK_DOCKER_NETWORK#g" \
    -e "s#__DOCKER_ENTRYPOINT#$TRAEFIK_DOCKER_ENTRYPOINT#g" \
    -e "s#__ACME_EMAIL_ADDRESS#$TRAEFIK_ACME_EMAIL_ADDRESS#g" \
    -e "s#__ACME_DNS_CHALLENGE_PROVIDER#$TRAEFIK_ACME_DNS_CHALLENGE_PROVIDER#g"
fi

exec "$@"
