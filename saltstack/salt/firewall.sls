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
      - Make sure firewall is running
    - order:
      - 101

Save firewall rules:
  cmd.run:
    - name: iptables-save > {{ pillar['firewall']['rules_path'] }}
    - order:
      - 102

Enable firewall service:
  service.enabled:
    - name: iptables

Make sure firewall is running:
  service.running:
    - name: iptables
