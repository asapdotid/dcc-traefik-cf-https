#!/bin/sh
set -e

# Traefik directories and files config
__TRAEFIK_CONFIG_FILE=/etc/traefik/traefik.yml
__TRAEFIK_DYNAMIC_CONFIG_DIR=/etc/traefik/dynamic
__TRAEFIK_DYNAMIC_DASHBAORD_CONFIG_FILE=$__TRAEFIK_DYNAMIC_CONFIG_DIR/dashboard.yml
__TRAEFIK_DYNAMIC_MIDDLEWARES_CONFIG_FILE=$__TRAEFIK_DYNAMIC_CONFIG_DIR/middlewares.yml

# Shell script variables concanated
__DASHBOARD_URL=$(echo 'Host(`'$TRAEFIK_DASHBOARD_SUBDOMAIN'.'$TRAEFIK_DOMAIN_NAME'`)')
__PASSWORD_DECODE=$(echo "$TRAEFIK_BASIC_AUTH_PASSWORD_HASH" | openssl enc -d -base64)
__BASIC_AUTH=$(echo "$TRAEFIK_BASIC_AUTH_USERNAME:$__PASSWORD_DECODE")
__CORS_ALLOW_HEADERS=$(echo "$TRAEFIK_MID_CORS_ALLOW_HEADERS" | sed -E 's/^|$/"/g; s/ /","/g')
__CORS_ALLOW_METHODS=$(echo "$TRAEFIK_MID_CORS_ALLOW_METHODS" | sed -E 's/^|$/"/g; s/ /","/g')
__SEC_HOSTS_PROXY=$(echo "$TRAEFIK_MID_SEC_HOSTS_PROXY" | sed -E 's/^|$/"/g; s/ /","/g')
__CORS_ALLOW_ORIGIN_LIST=$(echo "$TRAEFIK_MID_CORS_ALLOW_ORIGIN_LIST" | sed -E 's/^|$/"/g; s/ /","/g')

# Environment Variable Name (Authentication token)
if [ "$TRAEFIK_ACME_DNS_CHALLENGE_PROVIDER" = 'cloudflare' ]; then
  export CLOUDFLARE_DNS_API_TOKEN="$TRAEFIK_ACME_DNS_CHALLENGE_PROVIDER_TOKEN"
else
  echo "Invalid ACME DNS challenge provider. Please use cloudflare."
  exit 1
fi

# Modify traefik config
if [ -f "$__TRAEFIK_CONFIG_FILE" ]; then
  yq eval \
    'with(.entryPoints.https.http.tls; .domains = [{"main": "'$TRAEFIK_DOMAIN_NAME'", "sans": ["*.'$TRAEFIK_DOMAIN_NAME'"]}]) |
    with(.certificatesResolvers.letsEncrypt.acme; .email = "'$TRAEFIK_ACME_DNS_CHALLENGE_PROVIDER_EMAIL'") |
    with(.certificatesResolvers.letsEncrypt.acme.dnsChallenge; .provider = "'$TRAEFIK_ACME_DNS_CHALLENGE_PROVIDER'") |
    with(.api; .dashboard = '$TRAEFIK_DASHBOARD') |
    with(.log; .level = "'$TRAEFIK_LOG_LEVEL'")' \
    -i "$__TRAEFIK_CONFIG_FILE"
fi

# Modify traefik dashboard config
if [ -f "$__TRAEFIK_DYNAMIC_DASHBAORD_CONFIG_FILE" ]; then
  yq eval \
    'with(.http.routers.dashboard; .rule = "'$__DASHBOARD_URL'")' \
    -i "$__TRAEFIK_DYNAMIC_DASHBAORD_CONFIG_FILE"
fi

# Modify traefik middlewares config
if [ -f "$__TRAEFIK_DYNAMIC_MIDDLEWARES_CONFIG_FILE" ]; then
  ## Custom basic auth
  yq eval \
    'with(.http.middlewares.traefikBasicAuth.basicAuth; .users = ["'$__BASIC_AUTH'"])' \
    -i "$__TRAEFIK_DYNAMIC_MIDDLEWARES_CONFIG_FILE"

  ## Custom rate limit
  yq eval \
    'with(.http.middlewares.midRateLimit.rateLimit; .average = '$TRAEFIK_MID_RATE_LIMIT_AVERAGE') |
    with(.http.middlewares.midRateLimit.rateLimit; .burst = '$TRAEFIK_MID_RATE_LIMIT_BURST')' \
    -i "$__TRAEFIK_DYNAMIC_MIDDLEWARES_CONFIG_FILE"

  ## Custom security headers
  yq eval \
    'with(.http.middlewares.midSecurityHeaders.headers.customResponseHeaders; .X-Robots-Tag = "'$TRAEFIK_MID_SEC_CUST_RESPONSE_X_ROBOTS_TAG'") |
    with(.http.middlewares.midSecurityHeaders.headers.customResponseHeaders; .server = "'$TRAEFIK_MID_SEC_CUST_RESPONSE_X_FORWARDED_SERVER'") |
    with(.http.middlewares.midSecurityHeaders.headers.customResponseHeaders; .X-Forwarded-Proto = "'$TRAEFIK_MID_SEC_CUST_RESPONSE_X_FORWARDED_PROTO'") |
    with(.http.middlewares.midSecurityHeaders.headers.customRequestHeaders; .X-Forwarded-Proto = "'$TRAEFIK_MID_SEC_CUST_REQUEST_X_FORWARDED_PROTO'") |
    with(.http.middlewares.midSecurityHeaders.headers.sslProxyHeaders; .X-Forwarded-Proto = "'$TRAEFIK_MID_SEC_CUST_SSL_PROXY_X_FORWARDED_PROTO'") |
    with(.http.middlewares.midSecurityHeaders.headers; .hostsProxyHeaders = ['$__SEC_HOSTS_PROXY']) |
    with(.http.middlewares.midSecurityHeaders.headers; .referrerPolicy = "'$TRAEFIK_MID_SEC_REFERRER_POLICY'") |
    with(.http.middlewares.midSecurityHeaders.headers; .contentTypeNosniff = '$TRAEFIK_MID_SEC_CONTENT_TYPE_NO_SNIFF') |
    with(.http.middlewares.midSecurityHeaders.headers; .browserXssFilter = '$TRAEFIK_MID_SEC_BROWSER_XSS_FILTER') |
    with(.http.middlewares.midSecurityHeaders.headers; .forceSTSHeader = '$TRAEFIK_MID_SEC_FORCE_STS_HEADER') |
    with(.http.middlewares.midSecurityHeaders.headers; .stsIncludeSubdomains = '$TRAEFIK_MID_SEC_STS_INCLUDE_SUBDOMAIN') |
    with(.http.middlewares.midSecurityHeaders.headers; .stsSeconds = '$TRAEFIK_MID_SEC_STS_SECONDS') |
    with(.http.middlewares.midSecurityHeaders.headers; .stsPreload = '$TRAEFIK_MID_SEC_STS_PRELOAD') |
    with(.http.middlewares.midSecurityHeaders.headers; .frameDeny = '$TRAEFIK_MID_SEC_FRAME_DENY')' \
    -i "$__TRAEFIK_DYNAMIC_MIDDLEWARES_CONFIG_FILE"

  ## Custom content security policy
  sed \
    -e "s#__TRAEFIK_MID_SEC_CONTENT_SECURITY_POLICY#$TRAEFIK_MID_SEC_CONTENT_SECURITY_POLICY#g" \
    -i "$__TRAEFIK_DYNAMIC_MIDDLEWARES_CONFIG_FILE"

  ## Custom permission policy
  sed \
    -e "s#__TRAEFIK_MID_SEC_PERMISSION_POLICY#$TRAEFIK_MID_SEC_PERMISSION_POLICY#g" \
    -i "$__TRAEFIK_DYNAMIC_MIDDLEWARES_CONFIG_FILE"

  ## Custom CORS headers
  yq eval \
    'with(.http.middlewares.midCorsHeaders.headers; .accessControlAllowCredentials = '$TRAEFIK_MID_CORS_ALLOW_CREDENTIALS') |
    with(.http.middlewares.midCorsHeaders.headers; .accessControlAllowHeaders = ['$__CORS_ALLOW_HEADERS']) |
    with(.http.middlewares.midCorsHeaders.headers; .accessControlAllowMethods = ['$__CORS_ALLOW_METHODS']) |
    with(.http.middlewares.midCorsHeaders.headers; .accessControlAllowOriginList = ['$__CORS_ALLOW_ORIGIN_LIST']) |
    with(.http.middlewares.midCorsHeaders.headers; .accessControlMaxAge = '$TRAEFIK_MID_CORS_MAX_AGE') |
    with(.http.middlewares.midCorsHeaders.headers; .addVaryHeader = '$TRAEFIK_MID_CORS_ADD_VERY_HEADER')' \
    -i "$__TRAEFIK_DYNAMIC_MIDDLEWARES_CONFIG_FILE"

  ## Custom cache response headers
  yq eval \
    'with(.http.middlewares.midCacheHeaders.headers.customResponseHeaders; .Cache-Control = "'$TRAEFIK_MID_RESPONSE_CACHE_CONTROL'")' \
    -i "$__TRAEFIK_DYNAMIC_MIDDLEWARES_CONFIG_FILE"

  ## Custom compression
  yq eval \
    'with(.http.middlewares.midGzip; .compress = '$TRAEFIK_MID_COMPRESS')' \
    -i "$__TRAEFIK_DYNAMIC_MIDDLEWARES_CONFIG_FILE"

fi

exec "$@"
