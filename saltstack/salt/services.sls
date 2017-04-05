Make sure libvirtd is enabled:
  service.enabled:
    - name: libvirtd
    - require:
      - pkg: libvirt

Make sure NetworkManager is enabled:
  service.enabled:
    - name: NetworkManager
    - require:
      - pkg: networkmanager

Make sure ssdm is enabled:
  service.enabled:
    - name: ssdm
    - require:
      - pkg: ssdm
