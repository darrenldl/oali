Desktop environment:
  pkg.installed:
    - pkgs:
      # - xorg
      # - xfce4
      # - xfce4-goodies
      # - xfce4-notifyd
      - wayland
      - lxqt
      - sddm
      - kwin
      - systemsettings

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

