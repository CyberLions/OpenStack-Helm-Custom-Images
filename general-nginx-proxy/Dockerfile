FROM ubuntu:22.04

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install common dependencies
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    nginx \
    libnginx-mod-stream \
    gettext-base \
    python3 \
    iptables \
    net-tools \
    iproute2 \
    dnsutils \
    iputils-ping \
    procps \
    git \
    sudo

# Make the entrypoint script executable
RUN chmod +x /entrypoint.sh

# Clean up
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Default environment variables
ENV PROXY_PASS_DEFAULT="10.0.103.2"
ENV PROXY_PORT_DEFAULT="80"
ENV NGINX_PORT="80"

# Expose the Nginx port
EXPOSE 80 443

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]
