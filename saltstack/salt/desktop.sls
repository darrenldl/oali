Desktop environment:
  pkg.installed:
    - pkgs:
      - xorg
      # - xfce4
      # - xfce4-goodies
      # - xfce4-notifyd
      - wayland
      - lxqt
      - sddm
      - kwin
      - systemsettings

Window manager related:
  pkg.installed:
    - pkgs:
      - wmctrl

Terminal recording:
  pkg.installed:
    - pkgs:
      - asciinema

Screenshot:
  pkg.installed:
    - pkgs:
      - spectacle

File manager:
  pkg.installed:
    - pkgs:
      - ranger
      - thunar
      - thunar-volman

Login manager:
  pkg.installed:
    - pkgs:
      - sddm

Audio server:
  pkg.installed:
    - pkgs:
      - pulseaudio
      - paprefs
      - pavucontrol

Screensaver:
  pkg.installed:
    - pkgs:
      - i3lock
      # - xscreensaver

