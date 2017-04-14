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

Make sure ssdm is enabled:
  service.enabled:
    - name: ssdm
    - require:
      - pkg: Desktop environment
