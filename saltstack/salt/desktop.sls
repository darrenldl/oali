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

Screenshot:
  pkg.installed:
    - pkgs:
      - spectacle

File manager:
  pkg.installed:
    - pkgs:
      - ranger

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

