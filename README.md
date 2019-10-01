# OCaml Arch Linux Installer
[![Build Status](https://travis-ci.org/darrenldl/oali.svg?branch=master)](https://travis-ci.org/darrenldl/oali)

### Description
Oali is an installer written in OCaml which sets up a Arch Linux installation with following variations
- 3 disk layouts
  - Single system disk (installer does partitioning for you)
  - You pick the partitions for `/boot` `/` etc manually 
  - Single system partition (you pick an existing partition on a disk) + USB key (partitioned by installer)
- Optional full disk encryption
- Optional `linux-hardened` kernel installation

Oali aims to be smart and hassle free, so following features are included as a result
- Automatic adjustment of dialogues and settings based on whether the live CD is running in UEFI or BIOS mode

### Encryption specifics
In all disk layouts, system partition (i.e. `/`) is protected by a keyfile

The keyfile is stored in within the initramfs in boot partition, which is protected by a user provided passphrase

LUKS setup is used for all encrypted partitions.

If in UEFI mode, the ESP partition will be present but is not (and cannot be) encrypted.

### Post-install notes
After installation, several files will be present in `/root/llsh_pack` (all of the files are to be accessed/executed by root)
- `salt_exec.sh` allows you start the saltstack setup, present only if you answered yes to using saltstack for your further setup
- `oli_setup_note` contains description of the files
- `usb_key_mount.sh` allows you to mount your USB key easily and reliably
- `usb_key_umount.sh` allows you to unmount your USB key easily and reliably
- `useradd_helper_restructed.sh` and `useradd_helper_as_powerful.sh` allow you to add more users in the same manner as used by setup.sh

### Misc. notes
Saltstack files related
- currently linux-lts is enabled in the salt state files as a measure to avoid lock out due to kernel updates

### Prerequisites
- Working internet connection
- Partitioning done for system partition
- USB key (data will be lost)

### Space requirement
- USB key (if you intend to use disk layout that utilises a USB key)
  - 1 GiB USB drive will be very sufficient
- System drive
  - Current salt states download/install around 10 GiB of data

### Instructions
The OCaml code is not self contained, thus if you choose to compile it yourself, you will need to install various dependencies.

For deployment purposes, it is recommended that you use the static binaries provided, which you can download via [GitHub releases](https://github.com/darrenldl/ocaml-linux-installer/releases)

The static binaries of the installer are built via Travis CI using `ocaml/opam2:alpine` Docker image, and should be able to run on Arch Linux live CD without any further setup

### License
MIT
