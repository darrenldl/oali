Enable echo/noise-cancellation:
  file.append:
    - name: {{ pillar['pulseaudio']['config_path'] }}
    - text:
      # Copied from Archwiki
      # URL : https://wiki.archlinux.org/index.php/PulseAudio/Troubleshooting#Enable_Echo.2FNoise-Cancelation
      - ### Enable Echo/Noise-Cancellation
      - load-module module-echo-cancel
