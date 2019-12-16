# OCaml Arch Linux Installer
[![Build Status](https://travis-ci.org/darrenldl/oali.svg?branch=master)](https://travis-ci.org/darrenldl/oali)

## Warning
- Oali is primarily developed for my personal use, so it is not designed to be general.
  If you require it to follow a vastly different workflow, consider forking it and adjusting it accordingly.

- Oali is not supported by Arch Linux devs or the community, and you should not ask anything
  about it at Arch Linux reddit or forum

- Only the tagged releases are considered usable. You should never rely on `master` or `dev` branch to be working.

Anyhow, if you think your desired installation is quite close to mine, then continue reading

## Description
Oali is an installer written in OCaml which sets up a (very) opinionated Arch Linux installation with following variations

- 3 disk layouts

  - Single system disk (installer does partitioning for you)

  - You pick the partitions for `/boot`, `/` etc manually 

  - Single system partition (you pick an existing partition on a disk) + USB key (partitioned by installer)

- Optional full disk encryption

- Optional LVM for system partitions (`/`, `/var`, `/home` are installed in separate logical volumes if enabled)

- Optional `linux-hardened` kernel installation

You may pick any combination of above choices and Oali will take the appropriate actions accordingly

Overall Oali aims to be snappy, minimal, smart, and hassle free. See **Specifics** section below and [OALI\_DOC](OALI_DOC.md) for more information.

## TODO

- Documentation of each task so user can determine if the actions
  to be taken are appropriate for their use case

- Resumable installation (add logging etc)

  - Partially fulfilled by answer remembering

- Static config file support (so installation is fully automated)

  - Partially fulfilled by answer remembering

- Whatever is missing from the original script

## Getting started
#### Prerequisites
- Working internet connection

- Disk layout choice dependent

  - If you are using **Single system disk**

    - then just a single disk is required, partitioning will be done automatically during which the partition table will be wiped

  - If you are using **Manual picking**

    - then you need to have the partioning done prior to Oali asking for the disk layout choice

  - If you are using **Single system partition + USB key**

    - then you need to have a single system partition ready somewhere, and a USB key.
      The USB key will be automatically partitioned, during which the partition table will be wiped

#### Space requirement

- USB key (if needed)

  - 1 GiB USB drive will be very sufficient

- System drive

  - Current salt states download/install around 10 GiB of data

#### Instructions
The OCaml code is not self contained, thus if you choose to compile it yourself, you will need to install various dependencies

For deployment purposes, it is recommended that you use the static binaries provided, which you can download via [GitHub releases](https://github.com/darrenldl/ocaml-linux-installer/releases)

Simply run the downloaded binary (i.e. `oali`) in live CD to get started

The static binaries of the installer are built via Travis CI using `ocaml/opam2:alpine` Docker image, and should be able to run on Arch Linux live CD without any further setup

## Answers to some "Why?" questions

- Why make an installer to begin with?

  - Mildly complex FDE setups, especially with LVM, are really laborious and error prone to set up,
    and unfortunately you can't really afford human errors during these set ups depending on the nature of installation

  - A lot of decisions are based on information processing and very mechanical - no point in having a human
    devoted to repeating deterministic steps

- Why not bash?

  - The previous iteration of this installer was written in bash actually (see `laptop/scripts/setup.sh` at [oali-profiles](https://github.com/darrenldl/oali-profiles)), but it only supported one disk layout and always have encryption

  - Adding a lot of decision making code and information handling code to bash code was really tedious and difficult

- Why OCaml?

  - I know I can do OCaml/Rust reasonably fast, but slow to a crawl with dynamically typed langs

  - Here is mostly a lot of handling of immutable information (e.g. processing of system information), where Rust doesn't carry a significant advantage over OCaml, and the overhead didn't seem worth it to me

## Specifics
#### Answer remembering
Oali remembers answers to dialogues when appropriate, i.e. for relatively static information like

- choice of editor

- hostname

- encryption parameters

The answers are stored in `oali_answers` folder in JSON format. Each task has its own JSON file with a normalised/santised name.

In each session, Oali will try to retrieve answers from the folder and the specific JSON file. Missing files/answers are treated
as not being stored.

#### EFI/BIOS
Oali automatically adjusts dialogues and settings based on whether the live CD is running in UEFI or BIOS mode

#### Disk layout choices
**Single system disk** - Oali slices the disk into ESP (if in EFI mode), boot and root partitions automatically

**Manual picking** - Oali just uses the choices you provide

**Single system partition + USB key** - Oali installs ESP (if in EFI mode), boot partitions on USB key, and root partition on the provided system partition

Oali will handle encryption along with other chores automatically with the disk layout you picked in mind, such as

- `/etc/crypttab` is set up only if the disk layout doesn't involve USB key

- `/etc/fstab` is adjusted to disable USB key partitions if disk layout uses USB key so USB key can be unplugged safely after booting up

#### Encryption specifics
Oali uses `cryptsetup` for LUKS setup, and allows you to toggle boot and root partition encryption separately

Note that it will ask for confirmation if you choose to encrypt boot but not root (which is a silly setup, but it'll oblige if you insist)

Oali will ask if you want to change the key iteration time (in millisec) and key size

#### LVM
Oali sets up a single physical volume and a single volume group, and three logical volumes for `/`, `/var`, and `/home`

The physical volume is encrypted if LUKS is enabled

#### Boot partitions
If in UEFI mode, the ESP partition will be present but is never (and cannot be) encrypted

If boot partition encryption is enabled, then it is protected by a passphrase

#### System partition
If system/root partition encryption is enabled, then it is protected by a keyfile

The keyfile is stored in within the initramfs in boot partition

#### Profiles (optional)
Profiles are prebuilt SaltStack and script files that might suit specific scenarios

Currently there are 2 profiles
- Laptop (can also be used by a desktop)
- Server

Note that the profiles only affect what files are installed for post-bootstrapping phase,
i.e. all the above actions are supported by Oali regardless
of which profile you pick

You can also use a customised profile: start by forking [oali-profiles](https://github.com/darrenldl/oali-profiles)
modify the relevant files to your liking, and select "Custom" in the profile menu, and provide your git repo URL

#### Post-bootstrapping
After initial installation, several files will be present in `/root/oali_pack` (all of the files are to be accessed/executed by root)
- `salt_exec.sh` allows you start the saltstack setup, present only if you answered yes to using saltstack for your further setup
- `oali_setup_note` contains description of the files
- `usb_key_mount.sh` allows you to mount your USB key easily and reliably
- `usb_key_umount.sh` allows you to unmount your USB key easily and reliably
- `useradd_helper_restructed.sh` and `useradd_helper_as_powerful.sh` allow you to add more users in the same manner as used by setup.sh

## License
MIT
