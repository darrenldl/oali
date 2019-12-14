# Oali workflow details

This doc is generated via Oali. Please do not edit directly.

## 0. Shutting down



## 1. Asking if shutdown



## 2. Unmounting partitions



## 3. Asking if unmount partitions



## 4. Setting oali files permissions



## 5. Generating setup note



## 6. Customising SaltStack files



## 7. Copying SaltStack files



## 8. Select profile to use



## 9. Git cloning oali-profiles repo into current directory



## 10. Generating SaltStack execution script



## 11. Installing SaltStack



## 12. Ask if set up SaltStack



## 13. Transferring SSH public keys



## 14. Setting up SSH key directory



## 15. Enabling SSH server



## 16. Generating sshd_config



## 17. Installing SSH server



## 18. Ask if enable SSH server



## 19. Generating useradd helper scripts



## 20. Generating USB key mounting and unmounting scripts



## 21. Creating oali files folder



## 22. Setting user password



## 23. Setting user account



## 24. Setting up root password



## 25. Generating GRUB config



## 26. Installing GRUB to disk



## 27. Setting hardened kernel as default boot entry



## 28. Updating GRUB config: GRUB_CMDLINE_LINUX

If LUKS is enabled, adjusts the `GRUB_CMDLINE_LINUX` line in grub config to specify the the system partition, the associated keyfile, and root volume

## 29. Updating grub config: GRUB_ENABLE_CRYPTODISK



## 30. Installing bootloader packages



## 31. Installing dhcpcd



## 32. Installing wifi-menu



## 33. Updating package database



## 34. Setting up locale



## 35. Setting up hostname



## 36. Updating initramfs permissions



## 37. Installing hardened kernel



## 38. Recreating images

Recreate initramfs so the new mkinitcpio hooks are installed

## 39. Installing lvm2 onto system on disk



## 40. Adjusting mkinitcpio.conf

Adds appropriate mkinitcpio hooks

## 41. Setting up crypttab for unlocking and mounting /boot after boot



## 42. Installing keyfile for unlocking /boot after boot

Installs secondary keyfile for /boot

## 43. Installing keyfile for /

Sets up keyfile to be embedded into the initramfs

## 44. Generating fstab

Invokes `genfstab`, and comments out entry for `/boot`
if using the USB key disk layout

## 45. Installing base system (base linux base-devel)



## 46. Mounting disk



## 47. Setting up disk



## 48. Configure disk setup parameters



## 49. Checking if in EFI mode



## 50. Pick disk layout choice

User picks from one of the three disk layouts

- Single system disk

- Manual picking**

- Single system partition + USB key


## 51. Adjusting cryptsetup parameters for root partition

User can adjust the iteration time and key size here

## 52. Pick whether to encrypt ROOT partition (or physical volume for LVM)

If enabled, encrypts the system volume using LUKS v2

## 53. Adjusting cryptsetup parameters for boot partition

User can adjust the iteration time and key size here

## 54. Pick whether to encrypt BOOT partition

If enabled, encrypts the partition using LUKS v1
(GRUB does not support v2 yet

## 55. Pick whether to enable LVM

If enabled, creates a single volume group over the system partition,
and 3 logical volumes for `/`, `/var`, and `/home`.

If encryption is enabled, then the volume group is set up inside the encrypted partition


## 56. Asking if install hardened kernel



## 57. Asking for hostname



## 58. Installing git



## 59. Manual configuration of mirrorlist

Opens mirrorlist using the specified text editor

## 60. Automatic configuration of mirrorlist



## 61. Installing reflector



## 62. Asking if want to use reflector



## 63. Updating pacman database in live CD



## 64. Pick editor



## 65. Update time

Update Live CD time via NTP

## 66. Increase size of cow partition

Increases the size of cow partition to 2G

## 67. Initialising entropy of Oali



