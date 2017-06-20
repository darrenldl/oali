System monitoring:
  pkg.installed:
    - pkgs:
      - conky

Disk usage monitoring:
  pkg.installed:
    - pkgs:
      - ncdu
      - filelight

System info:
  pkg.installed:
    - pkgs:
      - hwdetect
      - lshw
      - hardinfo

Disk management:
  pkg.installed:
    - pkgs:
      - smartmontools
      - hddtemp
      - hdparm
      - sdparm

File system tools:
  pkg.installed:
    - pkgs:
      - mtools
      - dosfstools
      - efibootmgr
      - nfs-utils

Secure boot (EFI):
  pkg.installed:
    - pkgs:
      - efitools

Task management:
  pkg.installed:
    - pkgs:
      - lsof
      - htop

Mounting:
  pkg.installed:
    - pkgs:
      - udevil

NTP:
  pkg.installed:
    - pkgs:
      - ntp

File backup:
  pkg.installed:
    - pkgs:
      - borg

File synchronisation:
  pkg.installed:
    - pkgs:
      - unison

Partitioning:
  pkg.installed:
    - pkgs:
      - parted
      - gparted

Screen sessions:
  pkg.installed:
    - pkgs:
      - screen
