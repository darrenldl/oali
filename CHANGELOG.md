# 0.0.4
- Fixed `oali_pack` files permissions
- Added installation of `dhcpcd`

# 0.0.3
- Fixed boot partition cryptsetup parameters adjustment task unit
- Fixed partition size percentage calculation
- Fixed partition name computation code
  - Previously partition name may not be correctly deduced during formatting
- Added task unit for using `reflector` to generate more optimised mirrorlist
- Added SSH server setup and SSH keys transfer code
- Added a very rough main menu

# 0.0.2
- Added following user options when task unit fails
  - Skip
  - End install
- Added option to toggle boot partition encryption
- Split user account setup and password setup into two separate task units
- Fixed fstab cleaning code which deals with disk layout with USB key
- Fixed partition size calculation logic in partitioning code
- Moved task unit of hardened kernel setup to after boot loader related task unit
- Updated disk and partition discovery/look up code to be more robust

# 0.0.1
- Base version
