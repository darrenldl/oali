# Enable echo/noise-cancellation:
  # Copied from Archwiki
  # URL : https://wiki.archlinux.org/index.php/PulseAudio/Troubleshooting#Enable_Echo.2FNoise-Cancelation
  # file.append:
    # - name: {{ pillar['pulseaudio']['config_path'] }}
    # - text: |
        
        ### Enable Echo/Noise-Cancellation
        # load-module module-echo-cancel

Disable Mic boost:
  cmd.run:
    - name: /srv/salt/pulseaudio-disable-boost.rkt {{ pillar['pulseaudio_alsa']['config_dir'] }}
    - require:
      - pkg: Racket
