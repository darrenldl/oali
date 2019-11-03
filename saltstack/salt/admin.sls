System monitoring:
  pkg.installed:
    - pkgs:
#      - conky
       - gtop
       - glances
       - nmon

System info:
  pkg.installed:
    - pkgs:
      - screenfetch

# At:
#   pkg.installed:
#     - pkgs:
#       - at

Cron:
  pkg.installed:
    - pkgs:
      - fcron

Disk usage monitoring:
  pkg.installed:
    - pkgs:
      - ncdu
      - filelight
      - pydf

CPU limiting:
  pkg.installed:
    - pkgs:
      - cpulimit

System info:
  pkg.installed:
    - pkgs:
      - hwdetect
      - lshw
      - hardinfo

Log cleaning:
  pkg.installed:
    - pkgs:
      - logrotate # should already be installed since it is in base group, but leaving it here anyway

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
      - xfce4-taskmanager

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
      - restic

Cloud file access:
  pkg.installed:
    - pkgs:
      - rclone

Partitioning:
  pkg.installed:
    - pkgs:
      - parted
      - gparted

Remote desktop:
  pkg.installed:
    - pkgs:
      - remmina

Screen sessions:
  pkg.installed:
    - pkgs:
      - screen
      - tmux
      - tmuxp

Package management:
  pkg.installed:
    - pkgs:
      - pacman-contrib

Mirrorlist:
  pkg.installed:
    - pkgs:
      - reflector
