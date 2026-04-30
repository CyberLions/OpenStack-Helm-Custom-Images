ARG BASE_IMAGE=quay.io/airshipit/keystone:2025.1-ubuntu_noble_loci
FROM ${BASE_IMAGE}

RUN apt-get -y update && apt-get install -y libapache2-mod-auth-openidc curl ca-certificates
RUN update-ca-certificates
