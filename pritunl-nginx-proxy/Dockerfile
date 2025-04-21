FROM ubuntu:22.04

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and Pritunl client
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
    resolvconf \
    procps \
    sudo

RUN echo "deb https://repo.pritunl.com/stable/apt noble main" > /etc/apt/sources.list.d/pritunl.list \
    && gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 7568D9BB55FF9E5287D586017AE645C0CF8E292A \
    && gpg --armor --export 7568D9BB55FF9E5287D586017AE645C0CF8E292A | sudo tee /etc/apt/trusted.gpg.d/pritunl.asc \
    && apt update \
    && apt install -y pritunl-client

RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /etc/nginx/templates /conf/pritunl-profiles /var/log/pritunl

# Set up default Nginx configuration template
COPY pritunl-nginx-proxy/nginx.conf.template /etc/nginx/templates/
COPY pritunl-nginx-proxy/entrypoint.sh /entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /entrypoint.sh

# Default environment variables
ENV PROXY_PASS_DEFAULT="10.0.103.2"
ENV PROXY_PORT_DEFAULT="80"
ENV PRITUNL_PROFILE="cloud"
ENV NGINX_PORT="80"

# Expose the Nginx port
EXPOSE 80 443

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]
