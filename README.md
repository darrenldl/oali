# Linux_Laptop_Salt_Hard

This currently setups up an Archlinux installation with full disk encryption, requiring a USB key to boot and unlock.

Main system partition is encrypted using a keyfile, which is stored in the encrypted boot partition on USB key.
Boot partition is protected by a passphrase.
