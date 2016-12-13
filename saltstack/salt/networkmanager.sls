Enable WiFi stable MAC address randomisation:
  # Copied from Archwiki
  # URL : https://wiki.archlinux.org/index.php/NetworkManager#Configuring_MAC_Address_Randomization
  file.append:
    - name: {{ pillar['networkmanager']['config_path'] }}
    - text: |

        [connection]
        wifi.cloned-mac-address=stable

Enable Ethernet stable MAC address randomisation:
  # Copied from Archwiki
  # URL : https://wiki.archlinux.org/index.php/NetworkManager#Configuring_MAC_Address_Randomization
  file.append:
    - name: {{ pillar['networkmanager']['config_path'] }}
    - text: |

        [connection]
        ethernet.cloned-mac-address=stable

Enable IPv6 privacy extensions:
  # Copied from Archwiki
  # URL : https://wiki.archlinux.org/index.php/IPv6#NetworkManager
  file.append:
    - name: {{ pillar['networkmanager']['config_path'] }}
    - text: |

        [connection]
        ipv6.ip6-privacy=2
