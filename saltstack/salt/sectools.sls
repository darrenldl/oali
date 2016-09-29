System hardening:
  pkg.installed:
    - pkgs:
      - linux-grsec
      - paxd
      - checksec
      - pax-utils
      - paxtest

Sandboxing:
  pkg.installed:
    - pkgs:
      - firejail

File hashing:
  pkg.installed:
    - pkgs:
      - rhash
      - cfv

Cryptographic:
  pkg.installed:
    - pkgs:
      - ccrypt
      - gnupg
      - kdeutils-kgpg

Password management:
  pkg.installed:
    - pkgs:
      - keepassx2

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
