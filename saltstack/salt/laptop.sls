Ignore lid close:
  file.append:
    - name: /etc/systemd/logind.conf
    - text:
      - HandleLidSwitch=ignore

Battery monitor:
  pkg.installed:
    - pkgs:
      - cbatticon
