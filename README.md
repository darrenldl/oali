# Linux_Laptop_Salt_Hard

### Description
This currently setup an optionally hardened Arch Linux installation with full disk encryption, requiring a USB key to boot and unlock.

The script builds your USB key depending on whether the liveCD is running in UEFI mode or BIOS mode. After installation, the USB key needs to be booted from the mode your were on during installation.

### Hardening specifics
Outside of strict firewall that is suitable for normal user machine

setup.sh allows optional installation of linux-hardened package for Arch Linux

### Encryption specifics
Main system partition on computer drive is protected by a keyfile provided by user or generated from /dev/urandom (1MiB in size) by setup.sh.

**It is recommended that the user generates the keyfile on a trusted system with high level of entropy available prior to the installation.**

The keyfile is stored in the encrypted boot partition on USB key.

The encrypted boot partition on USB key is passphrase protected.

LUKS setup is used for all encrypted partitions.

If in UEFI mode, the ESP partition will be present but is not(and cannot be) encrypted.

### Notes
Note that this setup aims to move the weak point from the laptop drive to your USB key, that is, the laptop drive is better protected than your USB key in terms of encryption.

The implication then is that you should keep your USB key better protected physically(e.g. carried with you) than the laptop drive.

Also, you need to enter the passphrase of the boot partition twice during booting.

This setup does not store the keyfile in the kernel ram image, which may or may not be a benefit depending on your threat model.

It is **HIGHLY RECOMMENDED** that you leave salt execution to post-install phase using script provided (see below)

### Post-install notes
After installation, several files will be present in `/root/llsh_pack` (all of the files are to be accessed/executed by root)
- `salt_exec.sh`(present only if you answered yes to using saltstack for your further setup) allows you start the saltstack setup
- `llsh_setup_note` contains description of the files
- `usb_key_access_mount.sh` allows you to mount your USB key easily and reliably
- `usb_key_access_umount.sh` allows you to unmount your USB key easily and reliably
- `useradd_helper_restructed.sh` and `useradd_helper_as_powerful.sh` allow you to add more users in the same manner as used by setup.sh

### Misc. notes
Saltstack files related
- currently linux-lts is enabled in the salt state files as a measure to avoid lock out due to kernel updates

### Prerequisites
- Working internet connection
- Partitioning done for system partition
- USB key (data will be lost)

### Space requirement
- USB key
  - 1 GiB USB drive will be very sufficient
- System drive
  - Current salt states download/install around 10 GiB of data

### Instructions
#### Get the setup files
#### With Git
- Update package database and install git : `pacman -Sy git`
- Get the files : `git clone https://github.com/darrenldl/Linux_Laptop_Salt_Hard.git`

#### Without Git
- `wget https://github.com/darrenldl/Linux_Laptop_Salt_Hard/tarball/master -O - | tar xz`

#### Start the setup
- `cd Linux_Laptop_Salt_Hard/scripts; chmod u+x setup.sh; ./setup.sh`

### License
Unlicense - https://unlicense.org/
