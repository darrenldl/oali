Create disable firewire conf:
  file.managed:
    - name: {{ pillar['disable_firewire']['conf_path'] }}

Disable firewire related modules:
  file.append:
    - require:
      - Create disable firewire conf
    - name: {{ pillar['disable_firewire']['conf_path'] }}
    - text:
      - "blacklist ohci1394"
      - "blacklist sbp2"
      - "blacklist dv1394"
      - "blacklist raw1394"
      - "blacklist ieee1394"
      - "blacklist video1394"
      - "blacklist firewire-ohci"
      - "blacklist firewire-sbp2"
