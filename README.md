# OCaml Arch Linux Installer
[![Build Status](https://travis-ci.org/darrenldl/oali.svg?branch=master)](https://travis-ci.org/darrenldl/oali)

## Warning
Oali is still extremely early in development, and still WIP

It is difficult to test an installer targeting a live CD automatically, so right now it's still a lot of manual testing

Please do **NOT** use it for anything serious yet

## Description
Oali is an installer written in OCaml which sets up a Arch Linux installation with following variations
- 3 disk layouts
  - Single system disk (installer does partitioning for you)
  - You pick the partitions for `/boot`, `/` etc manually 
  - Single system partition (you pick an existing partition on a disk) + USB key (partitioned by installer)
- Optional full disk encryption
- Optional `linux-hardened` kernel installation

Oali aims to be smart and hassle free, so following features are included as a result
- Automatic adjustment of dialogues and settings based on whether the live CD is running in UEFI or BIOS mode

## Prerequisites
- Working internet connection
- Partitioning done for system partition
- USB key (data will be lost)

## Space requirement
- USB key (if you intend to use disk layout that utilises a USB key)
  - 1 GiB USB drive will be very sufficient
- System drive
  - Current salt states download/install around 10 GiB of data

## Instructions
The OCaml code is not self contained, thus if you choose to compile it yourself, you will need to install various dependencies.

For deployment purposes, it is recommended that you use the static binaries provided, which you can download via [GitHub releases](https://github.com/darrenldl/ocaml-linux-installer/releases)

The static binaries of the installer are built via Travis CI using `ocaml/opam2:alpine` Docker image, and should be able to run on Arch Linux live CD without any further setup

## Specifics

#### Disk layout choices
**Single system disk** - Oali slices the disks into ESP (if in EFI mode), boot and root partitions automatically

**Manual picking** - Oali just uses the choices you provide

**Single system partition + USB key** - Oali installs ESP (if in EFI mode), boot partitions on USB key, and root partition on the provided system partition

Oali will handle encryption along with other chores automatically with the disk layout you picked in mind, such as
- `/etc/crypttab` is set up only if the disk layout doesn't involve USB key
- `/etc/fstab` is adjusted to disable USB key partitions if disk layout uses USB key

#### Encryption specifics
Oali uses `cryptsetup` for LUKS setup, and allows you to toggle boot and root partition encryption separately

Note that it will ask for confirmation if you choose to encrypt boot but not root (which is a silly setup, but it'll oblige if you insist)

Oali will ask if you want to change the key iteration time (in millisec) and key size

#### Boot partitions
If in UEFI mode, the ESP partition will be present but is never (and cannot be) encrypted

If boot partition encryption is enabled, then it is protected by a passphrase

#### System partition
If system/root partition encryption is enabled, then it is protected by a keyfile

The keyfile is stored in within the initramfs in boot partition

#### Post-install notes
After installation, several files will be present in `/root/oali_pack` (all of the files are to be accessed/executed by root)
- `salt_exec.sh` allows you start the saltstack setup, present only if you answered yes to using saltstack for your further setup
- `oli_setup_note` contains description of the files
- `usb_key_mount.sh` allows you to mount your USB key easily and reliably
- `usb_key_umount.sh` allows you to unmount your USB key easily and reliably
- `useradd_helper_restructed.sh` and `useradd_helper_as_powerful.sh` allow you to add more users in the same manner as used by setup.sh

#### Misc. notes
Saltstack files related
- currently linux-lts is enabled in the salt state files as a measure to avoid lock out due to kernel updates

## License
MIT
