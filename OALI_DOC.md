# Oali workflow details

This doc is generated via Oali. Please do not edit directly.

## 0. Initialise entropy of Oali



## 1. Increase size of cow partition

Increases the size of cow partition to 2G

## 2. Update time

Update live CD time via NTP

## 3. Pick editor



## 4. Update pacman database in live CD

Just `pacman -Sy`

## 5. Ask if want to use reflector



## 6. Install reflector



## 7. Automatic configuration of mirrorlist

If `reflector` was enabled, then it is used to sort the mirrorlist by download rate

## 8. Manual configuration of mirrorlist

Opens mirrorlist using the specified text editor

## 9. Install git

Installs git onto live CD

## 10. Ask for hostname



## 11. Ask if install hardened kernel

Installs `linux-hardened` later if answered yes

## 12. Pick whether to enable LVM

If enabled, creates a single volume group over the system partition,
and 3 logical volumes for `/`, `/var`, and `/home`

If encryption is enabled as well, then the volume group is set up inside the encrypted partition


## 13. Pick whether to encrypt BOOT partition

If enabled, encrypts the partition using LUKS v1
(GRUB does not support v2 yet

## 14. Adjust cryptsetup parameters for boot partition

User can adjust the iteration time and key size here

## 15. Pick whether to encrypt ROOT partition (or physical volume for LVM)

If enabled, encrypts the system volume using LUKS v2

Oali will double check with the user if BOOT partition was configured to
to be encrypted, but picking no for ROOT partition here

User is allowed to continue said setup if they wishes to however


## 16. Adjust cryptsetup parameters for root partition

User can adjust the iteration time and key size here

## 17. Pick disk layout choice

User picks from one of the three disk layouts

- Single system disk

- Manual picking

- Single system partition + USB key


## 18. Check if in EFI mode



## 19. Configure disk setup parameters

Select disk and/or partitions based on previously picked disk layout,
then partitions the disk(s) based on the choices using `parted`

Partition sizes are calculated on Oali's side and passed to `parted`
as percentages to ensure the partition boundaries are aligned optimially

If disk layout is single disk, user is asked whether they want to
overprovision, and to pick the maximum percentage of disk to be used if so.
This is most useful for SSD scenarios where user may wish to overprovision manually.


## 20. Set up disk

LUKS, LVM, and file system formatting are set up at this stage when applicable

If LVM is enabled, then the logical volume sizes are as follows

- LV for `/`

  - 25% of the volume group or 25.0 GiB (whichever is smaller)

- LV for `/var`

  - 25% of the volume group or 250.0 GiB (whichever is smaller)

- LV for `/home`

  - 80% of the remaining space of volume group

- Leftover is intended for snapshot volumes


## 21. Mount disk

Mount all partitions with root being at `/mnt`

## 22. Install base system (base linux base-devel)



## 23. Generate fstab

Invokes `genfstab`, and comments out entry for `/boot`
if using the USB key disk layout

## 24. Install keyfile for /

Sets up keyfile to be embedded into the initramfs

## 25. Install keyfile for unlocking /boot after boot

Installs secondary keyfile for /boot if disk layout does not use USB key

The keyfile is referenced in crypttab later

## 26. Set up crypttab for unlocking and mounting /boot after boot

Append a line to crypttab file using the secondary keyfile for /boot,
allowing decryption of boot partition after booting

The line is then commented if disk layout uses USB key

## 27. Adjust mkinitcpio.conf

Adds appropriate mkinitcpio hooks based on LUKS and LVM choices specified

## 28. Install lvm2 onto system on disk

Install `lvm2` package into system on disk if LVM is enabled

## 29. Recreate images

Recreate initramfs so the new mkinitcpio hooks are installed

## 30. Install hardened kernel



## 31. Update initramfs permissions



## 32. Set up hostname



## 33. Set up locale



## 34. Install wifi-menu



## 35. Install dhcpcd



## 36. Install basic text editors

Installs `nano`, `vim`

## 37. Install bootloader packages

Install GRUB bootloader

## 38. Update GRUB config: GRUB_ENABLE_CRYPTODISK

If LUKS is enabled, then sets `GRUB_ENABLE_CRYPTODISK` to `y`

## 39. Update GRUB config: GRUB_CMDLINE_LINUX

If LUKS is enabled, adjusts the `GRUB_CMDLINE_LINUX` line in grub config to specify
the system partition, the associated keyfile, and root volume

## 40. Set hardened kernel as default boot entry



## 41. Install GRUB to disk

Invokes `grub-install` with parameters based on whether in BIOS or UEFI mode,
and also based on disk layout

Specifically, `--removable` flag is added if disk layout uses USB key

## 42. Generate GRUB config

Invokes `grub-mkconfig`

## 43. Set up root password



## 44. Set up user account



## 45. Set up user password



## 46. Create oali files folder

Sets up user facing notes for post-install stuff

## 47. Generate USB key mounting and unmounting scripts

If disk layout uses USB key, generates scripts with appropriate UUIDs
embedded for mounting and unmounting the USB key partitions

## 48. Generate useradd helper scripts



## 49. Ask if enable SSH server



## 50. Install SSH server



## 51. Generate sshd_config



## 52. Enable SSH server



## 53. Set up SSH key directory



## 54. Transfer SSH public keys

User can transfer the public key via command using `ncat` (for network transfer) and `gpg` (for symmetric encryption using a randomly generated alphanumeric passphrase)

Technically encryption of public is not necessary. The encryption
is to limit the damage of accidentally transferring private key instead
of the public key.


## 55. Ask if set up SaltStack



## 56. Install SaltStack



## 57. Generate SaltStack execution script



## 58. Git clone oali-profiles repo into current directory



## 59. Select profile to use



## 60. Copy SaltStack files



## 61. Customise SaltStack files



## 62. Generate setup note



## 63. Set oali files permissions



## 64. Ask if unmount partitions



## 65. Unmount partitions



## 66. Ask if shutdown



## 67. Shut down



