Create disable firewire conf:
  file.managed:
    - name: {{ pillar['disable_firewire']['conf_path'] }}
    - source: salt://disable_firewire.conf
    - replace: True
