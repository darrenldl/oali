Web browsers:
  pkg.installed:
    - pkgs:
      - firefox
      - chromium
      - falkon
      # - midori

Mail clients:
  pkg.installed:
    - pkgs:
      - thunderbird

# FTP:
#   pkg.installed:
#     - pkgs:

Network management:
  pkg.installed:
    - pkgs:
      - networkmanager
      - networkmanager-openvpn
      - network-manager-applet

Add user to nm-openvpn group:
  group.present:
    - name: nm-openvpn
    - addusers:
      - {{ pillar['user_info']['user_name'] }}
    - require:
      - Network management

SSH:
  pkg.installed:
    - pkgs:
      - openssh
      - putty
      - mosh

BitTorrent:
  pkg.installed:
    - pkgs:
      - deluge
