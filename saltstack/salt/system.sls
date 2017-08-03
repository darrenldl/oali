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

Power management:
  pkg.installed:
    - pkgs:
      - powertop
      - tlp

Optimisations:
  pkg.installed:
    - pkgs:
      - irqbalance

Reduce the timeout of systemd stop job:
  file.append:
    - name: {{ pillar['systemd']['config_path'] }}
    - text: |
        
        DefaultTimeoutStartSec=10s
        DefaultTimeoutStopSec=10s
