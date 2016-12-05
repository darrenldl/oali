# Linux_Laptop_Salt_Hard

### Description
This currently setups up an Arch Linux installation with full disk encryption, requiring a USB key to boot and unlock.

The script builds your USB key depending on whether the liveCD is running in UEFI mode or BIOS mode. After installation, the USB key needs to be booted from the mode your were on during installation.

### Encryption specifics
Main system partition on computer drive is protected by a keyfile generated from /dev/urandom (1MiB in size).

The keyfile is stored in the encrypted boot partition on USB key.

The encrypted boot partition on USB key is passphrase protected.

LUKS setup is used for all encrypted partitions.

If in UEFI mode, the ESP partition will be present but is not(and cannot be) encrypted.

### Notes
Note that this setup aims to move the weak point from the laptop drive to your USB key, that is, the laptop drive is better protected than your USB key in terms of encryption.

The implication then is that you should keep your USB key better protected physically(e.g. carried with you) than the laptop drive.

Also, you need to enter the passphrase of the boot partition twice during booting.

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
Unlicense - http://unlicense.org/
