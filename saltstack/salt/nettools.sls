Network statistics:
  pkg.installed:
    - pkgs:
      - vnstat

Network diagnosis:
  pkg.installed:
    - pkgs:
      - traceroute

Network monitoring:
  pkg.installed:
    - pkgs:
      - arpwatch

Network sniffing:
  pkg.installed:
    - pkgs:
      - wireshark-qt
      - tcpdump
      # - ettercap
      - ettercap-gtk

Network analysis:
  pkg.installed:
    - pkgs:
      - etherape

Add user to wireshark group:
  group.present:
    - name: wireshark
    - addusers:
      - {{ pillar['user_info']['user_name'] }}
    - require:
      - Network sniffing

Wireless tools:
  pkg.installed:
    - pkgs:
      - kismet

Fingerprinting/network scanning:
  pkg.installed:
    - pkgs:
      - p0f
      - nmap
      - arp-scan

Tunnelling:
  pkg.installed:
    - pkgs:
      - socat

General tunneling/traffic redirection:
  pkg.installed:
    - pkgs:
      - openbsd-netcat
