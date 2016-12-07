Qemu:
  pkg.installed:
    - pkgs:
      - qemu

Virtualbox:
  pkg.installed:
    - pkgs:
      - virtualbox

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
