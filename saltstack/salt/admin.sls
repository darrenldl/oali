System monitoring:
  pkg.installed:
    - pkgs:
      - conky
      - ncdu

System info:
  pkg.installed:
    - pkgs:
      - hwdetect
      - lshw
      - hardinfo

File system tools:
  pkg.installed:
    - pkgs:
      - mtools
      - dosfstools
      - efibootmgr

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
      - bup

Partitioning:
  pkg.installed:
    - pkgs:
      - parted
      - gparted
