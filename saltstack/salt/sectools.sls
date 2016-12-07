System hardening:
  pkg.installed:
    - pkgs:
      - linux-grsec
      - paxd
      - checksec
      - pax-utils
      - paxtest

Secure chat:
  pkg.installed:
    - pkgs:
      # Tox chat
      - qtox

Intrusion detection:
  pkg.installed:
    - pkgs:
      - aide

Anti-infoleak:
  pkg.installed:
    - pkgs:
      - bleachbit

Sandboxing:
  pkg.installed:
    - pkgs:
      - firejail
      - playpen

Hashing:
  pkg.installed:
    - pkgs:
      - rhash
      - cfv

Cryptographic:
  pkg.installed:
    - pkgs:
      - ccrypt
      - gnupg
      - gpa
      - veracrypt

Password management:
  pkg.installed:
    - pkgs:
      - keepassx2

Keyring:
  pkg.installed:
    - pkgs:
      - gnome-keyring

Anti-malware:
  pkg.installed:
    - pkgs:
      - clamav
      - rkhunter

Auditing:
  pkg.installed:
    - pkgs:
      - lynis

VPN:
  pkg.installed:
    - pkgs:
      - openvpn
