Desktop environment:
  pkg.installed:
    - pkgs:
      - xorg
      # - xfce4
      # - xfce4-goodies
      # - xfce4-notifyd
      - lxqt
      - sddm
      - kwin
      - systemsettings

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

