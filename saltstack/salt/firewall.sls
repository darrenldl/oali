# Install FWBuilder:
#   pkg.installed:
#     - pkgs:
#       - fwbuilder

Install ferm:
  pkg.installed:
    - pkgs:
      - ferm

Copy ferm config:
  file.managed:
    - name: {{ pillar['firewall']['ferm_path'] }}
    - source: salt://basic_workstation.ferm
    - replace: True
    - require:
      - Install ferm

Apply ferm config:
  cmd.run:
    - name: ferm {{ pillar['firewall']['ferm_path'] }}
    - require:
      - Copy ferm config

Save IPv4 firewall rules:
  cmd.run:
    - name: iptables-save > {{ pillar['firewall']['rules_path'] }}
    - require:
      - Apply ferm config

Save IPv6 firewall rules:
  cmd.run:
    - name: ip6tables-save > {{ pillar['firewall']['rules6_path'] }}
    - require:
      - Apply ferm config

Enable IPv4 firewall service:
  service.enabled:
    - name: iptables
    - require:
      - Save IPv4 firewall rules

Enable IPv6 firewall service:
  service.enabled:
    - name: ip6tables
    - require:
      - Save IPv6 firewall rules

Make sure IPv4 firewall is running:
  service.running:
    - name: iptables
    - require:
      - Save IPv4 firewall rules

Make sure IPv6 firewall is running:
  service.running:
    - name: ip6tables
    - require:
      - Save IPv6 firewall rules
