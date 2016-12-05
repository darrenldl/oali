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
    - order:
      - 100

Apply ferm config:
  cmd.run:
    - name: ferm {{ pillar['firewall']['ferm_path'] }}
    - require:
      - Make sure IPv4 firewall is running
      - Make sure IPv6 firewall is running
    - order:
      - 101

Save IPv4 firewall rules:
  cmd.run:
    - name: iptables-save > {{ pillar['firewall']['rules_path'] }}
    - order:
      - 102

Save IPv6 firewall rules:
  cmd.run:
    - name: ip6tables-save > {{ pillar['firewall']['rules6_path'] }}
    - order:
      - 102

Enable IPv4 firewall service:
  service.enabled:
    - name: iptables

Enable IPv6 firewall service:
  service.enabled:
    - name: ip6tables

Make sure IPv4 firewall is running:
  service.running:
    - name: iptables

Make sure IPv6 firewall is running:
  service.running:
    - name: ip6tables
