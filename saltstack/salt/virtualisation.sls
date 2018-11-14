Qemu:
  pkg.installed:
    - pkgs:
      - qemu

Virtualbox:
  pkg.installed:
    - pkgs:
      - virtualbox
      - virtualbox-host-dkms

Virt manager:
  pkg.installed:
    - pkgs:
      - virt-manager
      # for bridged networking
      - bridge-utils
      # for NAT/DHCP for guests
      - dnsmasq
      # NAT networking
      - ebtables
      # firewall backend
      # - firewalld
