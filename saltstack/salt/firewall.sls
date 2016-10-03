Install ferm:
  pkg.installed:
    - pkgs:
      - ferm

Copy ferm config:
  file.managed:
    - name: [ 'firewall:ferm_path' ]
    - source: salt://basic_workstation_ferm
    - replace: True
    - require:
      - Install ferm:
        - pkg.installed

Apply ferm config:
  cmd.run:  
    - name: ferm [ 'firewall:ferm_path' ]
    - require:
      - Copy ferm config:
        - file.managed

Save firewall rules:
  cmd.run:
    - name: iptables-save > [ 'firewall:rules_path' ]
    - require:
      - Apply ferm config:
        - cmd.run

Enable firewall service:
  cmd.run:
    - name: systemctl enable iptables
