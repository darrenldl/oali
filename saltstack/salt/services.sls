# Make sure atd is enabled:
#   service.enabled:
#     - name : atd
#     - require :
#       - At

Make sure libvirtd is enabled:
  service.enabled:
    - name : libvirtd
    - require :
      - Virt manager

# Make sure firewalld is enabled:
#   service.enabled:
#     - name : firewalld
#     - require :
#       - Virt manager

Make sure NetworkManager is enabled:
  service.enabled:
    - name : NetworkManager
    - require :
      - Network management

Make sure sddm is enabled:
  service.enabled:
    - name : sddm
    - require :
      - Login manager

Make sure fcron is enabled:
  service.enabled:
    - name : fcron
    - require :
      - Cron

Make sure vnStat is enabled:
  service.enabled:
    - name : vnstat
    - require :
      - Network statistics
