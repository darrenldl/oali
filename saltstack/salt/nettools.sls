Network monitoring/debugging:
  pkg.installed:
    - pkgs:
      - wireshark-qt
      - arpwatch
      - nmap
      - tcpdump
      - vnstat

Firewall:
  pkg.installed:
    - pkgs:
      - ferm
