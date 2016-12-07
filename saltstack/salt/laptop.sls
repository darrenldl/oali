Ignore lid close:
  file.append:
    - name: /etc/systemd/logind.conf
    - text:
      - HandleLidSwitch=ignore
