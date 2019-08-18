System hardening:
  pkg.installed:
    - pkgs:
      # - paxd
      - checksec
      - pax-utils
      - paxtest

Secure chat:
  pkg.installed:
    - pkgs:
      # Tox chat
      - qtox

# Vulnerability scan/management:
#   pkg.installed:
#     - pkgs:
#       - openvas

Intrusion detection:
  pkg.installed:
    - pkgs:
      - aide

Anti-infoleak/privacy:
  pkg.installed:
    - pkgs:
      - bleachbit
      - perl-image-exiftool

Sandboxing:
  pkg.installed:
    - pkgs:
      - firejail

Hashing:
  pkg.installed:
    - pkgs:
      - rhash
      - cfv

Cryptographic:
  pkg.installed:
    - pkgs:
      - gnupg
      - gpa
      - veracrypt

Password management:
  pkg.installed:
    - pkgs:
      - keepass

Keyring:
  pkg.installed:
    - pkgs:
      - gnome-keyring

Anti-malware:
  pkg.installed:
    - pkgs:
      - rkhunter

Auditing:
  pkg.installed:
    - pkgs:
      - lynis

VPN:
  pkg.installed:
    - pkgs:
      - openvpn

Nitrokey:
  pkg.installed:
    - pkgs:
      - nitrokey-app
