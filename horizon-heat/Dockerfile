FROM docker.io/openstackhelm/horizon:2024.1-ubuntu_jammy

# Heat Dashboard:
RUN pip install heat-dashboard

# Horizon VPNaaS:
RUN apt update && apt install git -y
RUN cd ~ && git clone https://opendev.org/openstack/neutron-vpnaas-dashboard
RUN cd ~/neutron-vpnaas-dashboard && pip install .
RUN cp ~/neutron-vpnaas-dashboard/neutron_vpnaas_dashboard/enabled/_7100_project_vpn_panel.py /var/lib/openstack/lib/*/site-packages/openstack_dashboard/enabled/