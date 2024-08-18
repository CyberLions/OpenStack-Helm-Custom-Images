FROM docker.io/openstackhelm/keystone:2024.1-ubuntu_jammy

RUN apt-get -y update && apt-get install -y libapache2-mod-auth-openidc curl ca-certificates
RUN update-ca-certificates
