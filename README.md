# Linux_Laptop_Salt_Hard

### Description
This currently setups up an Archlinux installation with full disk encryption, requiring a USB key to boot and unlock.

Main system partition is encrypted using a keyfile, which is stored in the encrypted boot partition on USB key.

Boot partition is protected by a passphrase.

### Prerequisites
  - Working internet connection
  - Partitioning done for system partition
  - USB key (data will be lost)

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
