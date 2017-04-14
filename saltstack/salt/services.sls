Make sure libvirtd is enabled:
  service.enabled:
    - name: libvirtd
    - require:
      - pkg: Virt manager

Make sure NetworkManager is enabled:
  service.enabled:
    - name: NetworkManager
    - require:
      - pkg: Network management

Make sure sddm is enabled:
  service.enabled:
    - name: sddm
    - require:
      - pkg: Login manager
