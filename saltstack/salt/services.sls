Make sure libvirtd is enabled:
  service.enabled:
    - name: libvirtd
    - require:
      - virtualisation: Virt manager

Make sure NetworkManager is enabled:
  service.enabled:
    - name: NetworkManager
    - require:
      - internet: Network management

Make sure ssdm is enabled:
  service.enabled:
    - name: ssdm
    - require:
      - desktop: Desktop environment
