# Oali workflow details

This doc is generated via Oali. Please do not edit directly.

## 0. Initialising entropy of Oali



## 1. Increase size of cow partition

Increases the size of cow partition to 2G

## 2. Update time

Update Live CD time via NTP

## 3. Pick editor



## 4. Updating pacman database in live CD



## 5. Asking if want to use reflector



## 6. Installing reflector



## 7. Automatic configuration of mirrorlist



## 8. Manual configuration of mirrorlist

Opens mirrorlist using the specified text editor

## 9. Installing git



## 10. Asking for hostname



## 11. Asking if install hardened kernel



## 12. Pick whether to enable LVM

If enabled, creates a single volume group over the system partition,
and 3 logical volumes for `/`, `/var`, and `/home`

If encryption is enabled, then the volume group is set up inside the encrypted partition


## 13. Pick whether to encrypt BOOT partition

If enabled, encrypts the partition using LUKS v1
(GRUB does not support v2 yet

## 14. Adjusting cryptsetup parameters for boot partition

User can adjust the iteration time and key size here

## 15. Pick whether to encrypt ROOT partition (or physical volume for LVM)

If enabled, encrypts the system volume using LUKS v2

## 16. Adjusting cryptsetup parameters for root partition

User can adjust the iteration time and key size here

## 17. Pick disk layout choice

User picks from one of the three disk layouts

- Single system disk

- Manual picking

- Single system partition + USB key


## 18. Checking if in EFI mode



## 19. Configure disk setup parameters



## 20. Setting up disk



## 21. Mounting disk



## 22. Installing base system (base linux base-devel)



## 23. Generating fstab

Invokes `genfstab`, and comments out entry for `/boot`
if using the USB key disk layout

## 24. Installing keyfile for /

Sets up keyfile to be embedded into the initramfs

## 25. Installing keyfile for unlocking /boot after boot

Installs secondary keyfile for /boot

## 26. Setting up crypttab for unlocking and mounting /boot after boot



## 27. Adjusting mkinitcpio.conf

Adds appropriate mkinitcpio hooks

## 28. Installing lvm2 onto system on disk



## 29. Recreating images

Recreate initramfs so the new mkinitcpio hooks are installed

## 30. Installing hardened kernel



## 31. Updating initramfs permissions



## 32. Setting up hostname



## 33. Setting up locale



## 34. Updating package database



## 35. Installing wifi-menu



## 36. Installing dhcpcd



## 37. Installing bootloader packages



## 38. Updating GRUB config: GRUB_ENABLE_CRYPTODISK



## 39. Updating GRUB config: GRUB_CMDLINE_LINUX

If LUKS is enabled, adjusts the `GRUB_CMDLINE_LINUX` line in grub config to specify the the system partition, the associated keyfile, and root volume

## 40. Setting hardened kernel as default boot entry



## 41. Installing GRUB to disk



## 42. Generating GRUB config



## 43. Setting up root password



## 44. Setting user account



## 45. Setting user password



## 46. Creating oali files folder



## 47. Generating USB key mounting and unmounting scripts



## 48. Generating useradd helper scripts



## 49. Ask if enable SSH server



## 50. Installing SSH server



## 51. Generating sshd_config



## 52. Enabling SSH server



## 53. Setting up SSH key directory



## 54. Transferring SSH public keys



## 55. Ask if set up SaltStack



## 56. Installing SaltStack



## 57. Generating SaltStack execution script



## 58. Git cloning oali-profiles repo into current directory



## 59. Select profile to use



## 60. Copying SaltStack files



## 61. Customising SaltStack files



## 62. Generating setup note



## 63. Setting oali files permissions



## 64. Asking if unmount partitions



## 65. Unmounting partitions



## 66. Asking if shutdown



## 67. Shutting down



