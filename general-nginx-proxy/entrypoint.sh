#!/bin/bash
set -e

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# --- Dynamic Nginx config generation ---
declare -A SERVER_BLOCKS
declare -A SERVER_SSL_CONFIG

# Default server block to reject undefined hosts
DEFAULT_SERVER_BLOCK="
server {
    listen ${NGINX_PORT:-80} default_server;
    listen ${NGINX_HTTPS_PORT:-443} ssl default_server;
    server_name _;
    ssl_certificate /etc/nginx/ssl/default.crt;
    ssl_certificate_key /etc/nginx/ssl/default.key;
    return 444;
}
"

# Generate a self-signed certificate for the default server block
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/default.key -out /etc/nginx/ssl/default.crt \
    -subj "/CN=default-server"

i=1
while true; do
    HOST_VAR="ROUTE_${i}_HOST"
    PATH_VAR="ROUTE_${i}_PATH"
    DEST_VAR="ROUTE_${i}_DESTINATION"
    PORT_VAR="ROUTE_${i}_PORT"
    SSL_SECRET_VAR="ROUTE_${i}_SSL_SECRET_NAME"
    SSL_CERT_VAR="ROUTE_${i}_SSL_CERT_FILE"
    SSL_KEY_VAR="ROUTE_${i}_SSL_KEY_FILE"

    [ -z "${!HOST_VAR}" ] && break

    ROUTE_HOST="${!HOST_VAR}"
    ROUTE_PATH="${!PATH_VAR:-/}"
    ROUTE_DEST="${!DEST_VAR}"
    ROUTE_PORT="${!PORT_VAR:-80}"
    SSL_SECRET_NAME="${!SSL_SECRET_VAR}"
    SSL_CERT_FILE="${!SSL_CERT_VAR}"
    SSL_KEY_FILE="${!SSL_KEY_VAR}"

    log "Adding route: Host=$ROUTE_HOST Path=$ROUTE_PATH -> $ROUTE_DEST:$ROUTE_PORT"

    LOCATION_BLOCK="        location ${ROUTE_PATH} {
            proxy_pass http://${ROUTE_DEST}:${ROUTE_PORT};
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection \"upgrade\";
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
"
    SERVER_BLOCKS["$ROUTE_HOST"]+="$LOCATION_BLOCK"

    if [ -n "$SSL_SECRET_NAME" ] && [ -n "$SSL_CERT_FILE" ] && [ -n "$SSL_KEY_FILE" ]; then
        log "Enabling SSL for $ROUTE_HOST using secret $SSL_SECRET_NAME"
        SERVER_SSL_CONFIG["$ROUTE_HOST"]="
        listen ${NGINX_HTTPS_PORT:-443} ssl;
        ssl_certificate /etc/nginx/secrets/${SSL_SECRET_NAME}/${SSL_CERT_FILE};
        ssl_certificate_key /etc/nginx/secrets/${SSL_SECRET_NAME}/${SSL_KEY_FILE};
"
    fi

    i=$((i+1))
done

# Build dynamic server blocks
DYNAMIC_SERVER_BLOCKS=""
for HOST in "${!SERVER_BLOCKS[@]}"; do
    DYNAMIC_SERVER_BLOCKS+="
    server {
        listen ${NGINX_PORT:-80};
        server_name $HOST;
        ${SERVER_SSL_CONFIG[$HOST]}
${SERVER_BLOCKS[$HOST]}
    }"
done

log "Generating Nginx configuration..."

export DYNAMIC_SERVER_BLOCKS
export DEFAULT_SERVER_BLOCK

# Use envsubst to replace the markers
envsubst '${DYNAMIC_SERVER_BLOCKS} ${DEFAULT_SERVER_BLOCK}' \
    < /etc/nginx/templates/nginx.conf.template > /etc/nginx/nginx.conf

# --- Dynamic Stream (TCP) Proxy Configuration ---
# This section remains unchanged from the original script

log "Final Nginx configuration:"
cat /etc/nginx/nginx.conf

log "Starting Nginx reverse proxy..."
nginx -g "daemon off;"