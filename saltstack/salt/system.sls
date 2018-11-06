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

# Shutdown after too many failed PAM authentications (system-auth file):
#   file.managed:
#     - name: {{ pillar['pam']['system-auth-path'] }}
#     - source: salt://system-auth
#     - replace: True

# Shutdown after too many failed PAM authentications (pam_maybe_shutdown.sh script):
#   file.managed:
#     - name: {{ pillar['pam']['pam_maybe_shutdown_sh_path'] }}
#     - source: salt://pam_maybe_shutdown.sh
#     - mode: 755
#     - replace: True
