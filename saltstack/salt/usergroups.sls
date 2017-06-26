Add user to wireshark group:
  group.present:
    - name: wireshark
    - addusers:
      - {{ pillar['user_info']['user_name'] }}
    - require:
      - Network sniffing
