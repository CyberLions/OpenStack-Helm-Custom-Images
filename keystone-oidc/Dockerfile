ARG BASE_IMAGE=docker.io/openstackhelm/keystone:2024.2-ubuntu_jammy
FROM ${BASE_IMAGE}

RUN apt-get -y update && apt-get install -y libapache2-mod-auth-openidc curl ca-certificates
RUN update-ca-certificates
