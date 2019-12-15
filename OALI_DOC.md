# Oali workflow details

This doc is generated via Oali. Please do not edit directly.

## 0. Initialising entropy of Oali



## 1. Increase size of cow partition

Increases the size of cow partition to 2G

## 2. Update time

Update live CD time via NTP

## 3. Pick editor



## 4. Updating pacman database in live CD

Just `pacman -Sy`

## 5. Asking if want to use reflector



## 6. Installing reflector



## 7. Automatic configuration of mirrorlist

If `reflector` was enabled, then it is used to sort the mirrorlist by download rate

## 8. Manual configuration of mirrorlist

Opens mirrorlist using the specified text editor

## 9. Installing git

Installs git onto live CD

## 10. Asking for hostname



## 11. Asking if install hardened kernel

Installs `linux-hardened` later if answered yes

## 12. Pick whether to enable LVM

If enabled, creates a single volume group over the system partition,
and 3 logical volumes for `/`, `/var`, and `/home`

If encryption is enabled as well, then the volume group is set up inside the encrypted partition


## 13. Pick whether to encrypt BOOT partition

If enabled, encrypts the partition using LUKS v1
(GRUB does not support v2 yet

## 14. Adjusting cryptsetup parameters for boot partition

User can adjust the iteration time and key size here

## 15. Pick whether to encrypt ROOT partition (or physical volume for LVM)

If enabled, encrypts the system volume using LUKS v2

Oali will double check with the user if BOOT partition was configured to
to be encrypted, but picking no for ROOT partition here

User is allowed to continue said setup if they wishes to however


## 16. Adjusting cryptsetup parameters for root partition

User can adjust the iteration time and key size here

## 17. Pick disk layout choice

User picks from one of the three disk layouts

- Single system disk

- Manual picking

- Single system partition + USB key


## 18. Checking if in EFI mode



## 19. Configure disk setup parameters

Select disk and/or partitions based on previously picked disk layout,
then partitions the disk(s) based on the choices using `parted`

Partition sizes are calculated on Oali's side and passed to `parted`
as percentages to ensure the partition boundaries are aligned optimially


## 20. Setting up disk

LUKS, LVM, and file system formatting are set up at this stage when applicable

If LVM is enabled, then logical volume sizes are as follows

- LV for `/`

  - 25% of the volume group or 25.0 GiB (whichever is smaller)

- LV for `/var`

  - 25% of the volume group or 250.0 GiB (whichever is smaller)

- LV for `/home`

  - 80% of the remaining space of volume group

- Leftover is intended for snapshot volumes


## 21. Mounting disk

Mount all partitions with root being at `/mnt`

## 22. Installing base system (base linux base-devel)



## 23. Generating fstab

Invokes `genfstab`, and comments out entry for `/boot`
if using the USB key disk layout

## 24. Installing keyfile for /

Sets up keyfile to be embedded into the initramfs

## 25. Installing keyfile for unlocking /boot after boot

Installs secondary keyfile for /boot

The keyfile is referenced in crypttab later

## 26. Setting up crypttab for unlocking and mounting /boot after boot

Append a line to crypttab file using the secondary keyfile for /boot,
allowing decryption of boot partition after booting

The line is then commented if disk layout uses USB key

## 27. Adjusting mkinitcpio.conf

Adds appropriate mkinitcpio hooks based on LUKS and LVM choices specified

## 28. Installing lvm2 onto system on disk

Install `lvm2` package into system on disk if LVM is enabled

## 29. Recreating images

Recreate initramfs so the new mkinitcpio hooks are installed

## 30. Installing hardened kernel



## 31. Updating initramfs permissions



## 32. Setting up hostname



## 33. Setting up locale



## 34. Installing wifi-menu



## 35. Installing dhcpcd



## 36. Installing bootloader packages

Install GRUB bootloader

## 37. Updating GRUB config: GRUB_ENABLE_CRYPTODISK



## 38. Updating GRUB config: GRUB_CMDLINE_LINUX

If LUKS is enabled, adjusts the `GRUB_CMDLINE_LINUX` line in grub config to specify
the system partition, the associated keyfile, and root volume

## 39. Setting hardened kernel as default boot entry



## 40. Installing GRUB to disk

Invokes `grub-install` with parameters based on whether in BIOS or UEFI mode,
and also based on disk layout

Specifically, `--removable` flag is added if disk layout uses USB key

## 41. Generating GRUB config

Invokes `grub-mkconfig`

## 42. Setting up root password



## 43. Setting user account



## 44. Setting user password



## 45. Creating oali files folder

Sets up user facing notes for post-install stuff

## 46. Generating USB key mounting and unmounting scripts

If disk layout uses USB key, generates scripts with appropriate UUIDs
embedded for mounting and unmounting the USB key partitions

## 47. Generating useradd helper scripts



## 48. Ask if enable SSH server



## 49. Installing SSH server



## 50. Generating sshd_config



## 51. Enabling SSH server



## 52. Setting up SSH key directory



## 53. Transferring SSH public keys

User can transfer the public key via command using `ncat` (for network transfer) and `gpg` (for symmetric encryption using a randomly generated alphanumeric passphrase)

Technically encryption of public is not necessary. The encryption
is to limit the damage of accidentally transferring private key instead
of the public key.


## 54. Ask if set up SaltStack



## 55. Installing SaltStack



## 56. Generating SaltStack execution script



## 57. Git cloning oali-profiles repo into current directory



## 58. Select profile to use



## 59. Copying SaltStack files



## 60. Customising SaltStack files



## 61. Generating setup note



## 62. Setting oali files permissions



## 63. Asking if unmount partitions



## 64. Unmounting partitions



## 65. Asking if shutdown



## 66. Shutting down



