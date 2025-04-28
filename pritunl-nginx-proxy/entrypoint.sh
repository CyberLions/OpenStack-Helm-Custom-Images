#!/bin/bash
set -e

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Check if Pritunl profile is provided
if [ -z "$PRITUNL_PROFILE" ]; then
    log "No Pritunl profile specified. Running only as a reverse proxy."
else
    log "Connecting to Pritunl VPN using profile: $PRITUNL_PROFILE"
    
    # Check if the profile exists
    if [ ! -f "/conf/pritunl-profiles/$PRITUNL_PROFILE" ]; then
        log "Error: Profile /conf/pritunl-profiles/$PRITUNL_PROFILE not found!"
        exit 1
    fi

    log "Starting pritunl-client-service daemon..."
    pritunl-client-service &
    sleep 2

    
    # Import the profile
    pritunl-client add "/conf/pritunl-profiles/$PRITUNL_PROFILE"
    
    # Get the profile ID
    pritunl-client list
    PROFILE_ID=$(pritunl-client list | grep -E '\| [a-z0-9]{14,} ' | head -n1 | awk -F'|' '{gsub(/ /,"",$2); print $2}')
    
    if [ -z "$PROFILE_ID" ]; then
        log "Error: Failed to get profile ID for $PRITUNL_PROFILE | $PROFILE_ID"
        exit 1
    fi
    
    log "Starting Pritunl connection with profile ID: $PROFILE_ID"
    
    # Start the connection in the background
    pritunl-client start "$PROFILE_ID" &
    
    # Wait for the connection to establish
    log "Waiting for VPN connection to establish..."
    sleep 5
    
    # Check if the connection is established
    ATTEMPTS=0
    MAX_ATTEMPTS=12
    while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
        if pritunl-client list | grep -q "|.*Active.*|"; then
            log "VPN connection established successfully!"
            break
        fi
        ATTEMPTS=$((ATTEMPTS+1))
        log "Waiting for VPN connection... ($ATTEMPTS/$MAX_ATTEMPTS)"
        sleep 5
    done
    
    if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
        log "Error: Failed to establish VPN connection after multiple attempts."
        log "Current status:"
        pritunl-client list
        exit 1
    fi
fi

# Generate additional route configurations based on environment variables
ADDITIONAL_ROUTES=""
i=1
while true; do
    PATH_VAR="ROUTE_${i}_PATH"
    DEST_VAR="ROUTE_${i}_DESTINATION"
    PORT_VAR="ROUTE_${i}_PORT"
    
    if [ -z "${!PATH_VAR}" ]; then
        break
    fi

    ROUTE_PATH="${!PATH_VAR}"
    ROUTE_DEST="${!DEST_VAR}"
    ROUTE_PORT="${!PORT_VAR:-80}"

    log "Adding route: $ROUTE_PATH -> $ROUTE_DEST:$ROUTE_PORT"

    ADDITIONAL_ROUTES="${ADDITIONAL_ROUTES}location ${ROUTE_PATH} {
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
    i=$((i+1))
done


# Export the additional routes for envsubst
export ADDITIONAL_ROUTES

# Process the Nginx configuration template
log "Generating Nginx configuration..."
envsubst '${PROXY_PASS_DEFAULT} ${PROXY_PORT_DEFAULT} ${NGINX_PORT} ${ADDITIONAL_ROUTES}' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/nginx.conf

# Start Nginx
log "Starting Nginx reverse proxy..."
nginx -g "daemon off;"
