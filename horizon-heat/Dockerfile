FROM docker.io/openstackhelm/horizon:2024.1-ubuntu_jammy

# Heat Dashboard:
RUN pip install heat-dashboard

# Horizon VPNaaS:
RUN apt update && apt install git -y
RUN cd ~ && git clone https://opendev.org/openstack/neutron-vpnaas-dashboard
RUN cd ~/neutron-vpnaas-dashboard && pip install .