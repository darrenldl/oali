# Hardened kernel:
#   pkg.installed:
#     - pkgs:
#       - linux-hardened
#       - linux-hardened-headers

Vanilla kernel:
  pkg.installed:
    - pkgs:
      - linux
      - linux-headers

LTS kernel:
  pkg.installed:
    - pkgs:
      - linux-lts
      - linux-lts-headers
