# 0.0.2
- Added following user options when task unit fails
  - Skip
  - End install
- Added option to toggle boot partition encryption
- Split user account setup and password setup into two separate task units
- Fixed fstab cleaning code which deals with disk layout with USB key
- Fixed partition size calculation logic in partitioning code
- Moved task unit of hardened kernel setup to after boot loader related task unit

# 0.0.1
- Base version
