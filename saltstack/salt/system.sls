Hardened kernel:
  pkg.installed:
    - pkgs:
      - linux-hardened
      - linux-hardened-headers

Vanilla kernel:
  pkg.installed:
    - pkgs:
      - linux
      - linux-headers
