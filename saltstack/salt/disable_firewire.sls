Disable firewire related modules:
  file.exists:
    - name: /etc/modprobe.d/disable_fireware.conf
  file.append:
    - require:
      - Disable firewire related modules:
        - file.exists
    - name: /etc/modprobe.d/disable_firewire.conf
    - text:
      - "blacklist ohci1394"
      - "blacklist sbp2"
      - "blacklist dv1394"
      - "blacklist raw1394"
      - "blacklist ieee1394"
      - "blacklist video1394"
      - "blacklist firewire-ohci"
      - "blacklist firewire-sbp2"
