Install ferm:
  pkg.installed:
    - pkgs:
      - ferm

Copy ferm config:
  file.managed:
    - name: {{ pillar['firewall']['ferm_path'] }}
    - source: salt://basic_workstation_ferm
    - replace: True
    - require:
      - Install ferm
    - order:
      - 100

Apply ferm config:
  cmd.run:  
    - name: ferm {{ pillar['firewall']['ferm_path'] }}
    - order:
      - 101

Save firewall rules:
  cmd.run:
    - name: iptables-save > {{ pillar['firewall']['rules_path'] }}
    - order:
      - 102

Enable firewall service:
  cmd.run:
    - name: systemctl enable iptables
    - order:
      - 103
