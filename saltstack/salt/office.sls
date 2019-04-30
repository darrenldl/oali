LaTeX:
  pkg.installed:
    - pkgs:
      - texstudio
      - texlive-most
      - texlive-lang
      - biber

General Office Software:
  pkg.installed:
    - pkgs:
      - libreoffice-still
      # - calligra

Calculator:
  pkg.installed:
    - pkgs:
      - speedcrunch
  
# E-book:
#   pkg.installed:
#     - pkgs:
#       - calibre

PDF:
  pkg.installed:
    - pkgs:
      - apvlv
      # - atril
      - okular
      - pdfsam
      - poppler

Note taking:
  pkg.installed:
    - pkgs:
      - cherrytree
      - zim

Time tracking:
  pkg.installed:
    - pkgs:
      - hamster-time-tracker

OCR:
  pkg.installed:
    - pkgs:
      - tesseract
      - tesseract-data
      - paperwork
