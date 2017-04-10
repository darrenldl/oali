Web browsers:
  pkg.installed:
    - pkgs:
      - firefox
      - chromium

Mail clients:
  pkg.installed:
    - pkgs:
      - thunderbird

FTP:
  pkg.installed:
    - pkgs:
      - filezilla

Network management:
  pkg.installed:
    - pkgs:
      - networkmanager
      - networkmanager-openvpn

Add user to nm-openvpn group:
  group.present:
    - name: nm-openvpn
    - addusers:
      - {{ pillar['user']['user_name'] }}
    - require:
      - Network management

SSH:
  pkg.installed:
    - pkgs:
      - openssh
      - putty

BitTorrent:
  pkg.installed:
    - pkgs:
      - deluge
