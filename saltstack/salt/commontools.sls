Text editor:
  pkg.installed:
    - pkgs:
      - vim
      - nano
      - gedit
      - geany

Desktop environment:
  pkg.installed:
    - pkgs:
      - xorg
      - xfce4
      - xfce4-goodies
      - xfce4-notifyd

Audio server:
  pkg.installed:
    - pkgs:
      - pulseaudio
      - paprefs
      - pavucontrol

Archiving:
  pkg.installed:
    - pkgs:
      - p7zip

Mounting:
  pkg.installed:
    - pkgs:
      - udevil

Partitioning:
  pkg.installed:
    - pkgs:
      - parted
      - gparted

File system tools:
  pkg.installed:
    - pkgs:
      - mtools
      - dosfstools
      - efibootmgr
      - ntfs-3g

Web browsers:
  pkg.installed:
    - pkgs:
      - firefox

Mail clients:
  pkg.installed:
    - pkgs:
      - thunderbird

Screensaver:
  pkg.installed:
    - pkgs:
      - i3lock

Virtualisation:
  pkg.installed:
    - pkgs:
      - qemu
      - virtualbox
      - virt-manager

Network management:
  pkg.installed:
    - pkgs:
      - networkmanager
      - network-manager-applet

SSH:
  pkg.installed:
    - pkgs:
      - openssh

Media:
  pkg.installed:
    - pkgs:
      - vlc
      - clementine
      - ffmpeg

FTP:
  pkg.installed:
    - pkgs:
      - filezilla

BitTorrent:
  pkg.installed:
    - pkgs:
      - deluge

Image:
  pkg.installed:
    - pkgs:
      - feh

NTP:
  pkg.installed:
    - pkgs:
      - ntp

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

Office:
  pkg.installed:
    - pkgs:
      - libreoffice-still
      - calligra
      - texstudio
      - calibre
      - zim

File backup:
  pkg.installed:
    - pkgs:
      - bup
      - rsync

Disk/partition image backup:
  pkg.installed:
    - pkgs:
      - partclone

Fonts:
  pkg.installed:
    - pkgs:
      - ttf-dejavu
