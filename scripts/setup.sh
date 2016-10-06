#!/bin/bash
#
# Author : darrenldl <dldldev@yahoo.com>
#
# License:
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org/>

default_wait=1
wait_and_clear() {
  if [[ $# == 0 ]]; then
    sleep $default_wait
  else
    sleep $1
  fi
  clear
}

INVALID_ANS="Invalid answer"
NO_COMMAND="Command not found"

clear

# Notes
echo "Notes:"
echo "  Please note that you need to have an external USB drive for this installation"
echo "Press enter to continue"
read

clear

# Show requirement
echo "Requirements:"
echo "  The main system partition should be setup already(no need to be formatted)"
echo ""
echo "Please fulfill the requirements above if any is missing,"
echo "and press enter after partitioning to continue"
read

clear

# Show stages
echo "Stages:"
echo "  choose editor"
echo "  configure mirrorlist"
echo "  choose system partition"
echo "  setup encryption and USB key"
echo "  install system"
echo "  setup GRUB"
echo "  copy USB key mounting/unmounting scripts into new system"
echo "  basic setup of system"
echo "  copy saltstack files"
echo "  execute salt for final setup"
echo "  restart"
echo "  "
echo ""
echo "Press enter to continue"
read

clear

# Update time
echo "Updating time"
timedatectl set-ntp true

wait_and_clear

# Choose editor
echo "Choose editor"
echo ""

end=false
while ! $end; do
  EDITOR=""
  echo -n "Please specifiy an editor to use : "
  read EDITOR

  if hash $EDITOR &>/dev/null; then
    echo "Editor selected :" $EDITOR
    while true; do
      echo -n "Is this correct? y/n : "
      read ans
      if   [[ $ans == "y" ]]; then
        end=true
        break
      elif [[ $ans == "n"  ]]; then
        end=false
        break
      else
        echo -e $INVALID_ANS
      fi
    done
  else 
    echo -e $NO_COMMAND
  fi
done

clear

# Configure mirrorlist
echo "Configure mirrorlist"
echo ""

echo "Press enter to continue"
read

mirrorlist_path="/etc/pacman.d/mirrorlist"
end=false
while ! $end; do
  while true; do
    $EDITOR $mirrorlist_path

    clear

    echo -n "Finished editing? y/n : "
    read ans
    if   [[ $ans == "y" ]]; then
      end=true
      break
    elif [[ $ans == "n" ]]; then
      end=false
      break
    else
      echo -e $INVALID_ANS
    fi
  done
done

clear

# choose system partition
echo "Choose system partition"
echo ""

end=false
while ! $end; do
  echo -n "Please specify a partition to use : "
  read SYS_PART

  if [ -b $SYS_PART ]; then
    echo "System parition picked :" $SYS_PART
    while true; do
      echo -n "Is this correct? y/n : "
      read ans
      if   [[ $ans == "y" ]]; then
        end=true
        break
      elif [[ $ans == "n" ]]; then
        end=false
        break
      else
        echo -e $INVALID_ANS
      fi
    done
  else
    echo "Partition does not exist"
  fi
done

clear

# Setup encryption and USB key
echo "Setup encryption and USB key"
echo ""
echo "Warning : data on USB key will be lost"
echo ""

end=false
while ! $end; do
  echo -n "Please specify the USB key device : "
  read USB_KEY

  if [ -b "$USB_KEY" ]; then
    echo "Device picked :" "$USB_KEY"
    while true; do
      echo -n "Is this correct? y/n : "
      read ans
      if   [[ $ans == "y" ]]; then
        end=true
        break
      elif [[ $ans == "n" ]]; then
        end=false
        break
      else
        echo -e $INVALID_ANS
      fi
    done
  else
    echo "Device does not exist"
  fi
done

clear

## Partition the USB key
efi_firmware_path="/sys/firmware/efi"
echo "Preparing USB key"
if [ -e $efi_firmware_path ]; then
  echo "System is in UEFI mode"
  efi_mode=true
else
  echo "System is in BIOS mode"
  efi_mode=false
fi

clear

echo "Wiping paritioning info"
dd if=/dev/zero of="$USB_KEY" bs=512 count=2 &>/dev/null

wait_and_clear 2

if $efi_mode; then
  echo "Creating GPT partition table"
  parted "$USB_KEY" mklabel gpt &>/dev/null

  echo "Partitioning"
  parted -a optimal "$USB_KEY" mkpart primary fat32  0%  25% &>/dev/null
  parted -a optimal "$USB_KEY" mkpart primary       25%  50% &>/dev/null

  parted "$USB_KEY" set 1 boot on &>/dev/null

  USB_KEY_ESP="$USB_KEY"1

  echo "Formatting ESP partition"
  mkfs.fat -F32 "$USB_KEY_ESP"

  USB_KEY_ESP_UUID=$(blkid "$USB_KEY_ESP" | sed -n "s@\(.*\)UUID=\"\(.*\)\" TYPE\(.*\)@\2@p")

  USB_KEY_BOOT="$USB_KEY"2
else
  echo "Creating MBR partition table"
  parted "$USB_KEY" mklabel msdos &>/dev/null

  echo "Partitioning"
  parted -a optimal "$USB_KEY" mkpart primary  0%  25% &>/dev/null

  parted "$USB_KEY" set 1 boot on &>/dev/null

  USB_KEY_BOOT="$USB_KEY"1
fi

wait_and_clear 2

end=false
while ! $end; do
  echo "Do you want to overwrite partitions which will be encrypted with random bytes(/dev/urandom)? y/n : "
  read ans

  if   [[ $ans == "y" ]]; then
    echo "You entered yes"
    rand_wipe=true
  elif [[ $ans = "n" ]]; then
    echo "You entered no"
    rand_wipe=false
  else
    echo -e $INVALID_ANS
    continue
  fi

  while true; do
    echo -n "Is this correct? y/n : "
    read ans
    if   [[ $ans == "y" ]]; then
      end=true
      break
    elif [[ $ans == "n" ]]; then
      end=false
      break
    else
      echo -e $INVALID_ANS
    fi
  done
done

clear

if $rand_wipe; then
  while true; do
    echo "Ovewriting boot partition with random bytes"
    ddrescue --force /dev/urandom "$USB_KEY_BOOT" &>/dev/null
    if [[ $? == 0 ]]; then
      break
    else
      :
    fi
  done
fi

wait_and_clear

# Encrypt USB key boot partition
while true; do
  echo "Encrypting boot partition"
  cryptsetup -y luksFormat "$USB_KEY_BOOT"
  if [[ $? == 0 ]]; then
    break
  else
    :
  fi
done

USB_KEY_BOOT_UUID=$(blkid "$USB_KEY_BOOT" | sed -n "s@\(.*\)UUID=\"\(.*\)\" TYPE\(.*\)@\2@p")

clear

key_file_name="sys_part_key_file"
key_file_path="/tmp/"$key_file_name

echo "Generating keyfile (1 MiB in size) for system partition"
dd if=/dev/urandom of="$key_file_path" bs=1024 count=1024

wait_and_clear 2

# Encrypt main system partition
while true; do
  echo "Encrypting system partition"
  cryptsetup --key-file "$key_file_path" luksFormat $SYS_PART
  if [[ $? == 0 ]]; then
    break
  else
    :
  fi
done

SYS_PART_UUID=$(blkid "$SYS_PART" | sed -n "s@\(.*\)UUID=\"\(.*\)\" TYPE\(.*\)@\2@p")

wait_and_clear

# Prepare system partition
mount_path="/mnt"
mapper_name_sys="crypt_sys_root"
mapper_name_boot="crypt_boot"

echo "Unlocking system partition"
cryptsetup --key-file "$key_file_path" luksOpen $SYS_PART "$mapper_name_sys"

echo "Formatting system partition"
mkfs.ext4 /dev/mapper/"$mapper_name_sys"

echo "Mounting system partition"
mount /dev/mapper/"$mapper_name_sys" "$mount_path"

echo "Creating boot directory"
mkdir "$mount_path"/boot

echo "Generating fstab"
mkdir "$mount_path"/etc
genfstab -U "$mount_path" >> "$mount_path"/etc/fstab

wait_and_clear 2

while true; do
  echo "Unlocking boot partition"
  cryptsetup luksOpen $USB_KEY_BOOT "$mapper_name_boot"
  if [[ $? == 0 ]]; then
    break
  else
    :
  fi
done

echo "Formatting boot partition"
mkfs.ext4 /dev/mapper/"$mapper_name_boot"

wait_and_clear 2

echo "Mounting boot partition"
mount /dev/mapper/"$mapper_name_boot" "$mount_path"/boot

echo "Copying keyfile to boot directory"
cp "$key_file_path" "$mount_path"/boot

wait_and_clear 2

# Install base system
while true; do
  echo "Installing base system (base base-devel)"
  pacstrap /mnt base base-devel
  if [[ $? == 0 ]]; then
    break
  else
    :
  fi
done

clear

echo "Merging new fstab with configured fstab, if any"
if [ -e "$mount_path"/etc/fstab.pacnew ]; then
  cat "$mount_path"/etc/fstab >> "$mount_path"/etc/fstab.pacnew
  mv "$mount_path"/etc/fstab.pacnew "$mount_path"/etc/fstab
fi

wait_and_clear 2

# Setup hostname
end=false
while ! $end; do
  echo -n "Please enter hostname : "
  read host_name

  while true; do
    echo "You entered :" $host_name
    echo -n "Is this correct? y/n : "
    read ans
    if   [[ $ans == "y" ]]; then
      end=true
      break
    elif [[ $ans == "n" ]]; then
      end=false
      break
    else
      echo -e $INVALID_ANS
    fi
  done
done

echo $host_name > "$mount_path"/etc/hostname

wait_and_clear 2

echo "Setting locale"
sed -i "s@#en_US.UTF-8 UTF-8@en_US.UTF-8 UTF-8@g" "$mount_path"/etc/locale.gen
echo "LANG=en_US.UTF-8" > "$mount_path"/etc/locale.conf
arch-chroot "$mount_path" locale-gen

wait_and_clear 2

# Update database
while true; do
  echo "Updating package database"
  arch-chroot "$mount_path" pacman --noconfirm -Sy
  if [[ $? == 0 ]]; then
    break
  else
    :
  fi
done

clear

# Install grsecutiy and remove vanilla kernel
while true; do
  echo "Removing vanilla kernel"
  arch-chroot "$mount_path" pacman --noconfirm -R linux
  if [[ $? == 0 ]]; then
    break
  else
    :
  fi
done

wait_and_clear

while true; do
  echo "Installing Grsecurity kernel"
  arch-chroot "$mount_path" pacman --noconfirm -S linux-grsec
  if [[ $? == 0 ]]; then
    break
  else
    :
  fi
done

clear

while true; do
  echo "Setting root password"
  arch-chroot "$mount_path" passwd
  if [[ $? == 0 ]]; then
    break
  else
    :
  fi
done

clear

# Setup GRUB
while true; do
  echo "Installing grub package"
  arch-chroot "$mount_path" pacman --noconfirm -S grub
  if [[ $? == 0 ]]; then
    break
  else
    :
  fi
done

if $efi_mode; then
  while true; do
    echo "Installing efibootmgr package"
    arch-chroot "$mount_path" pacman --noconfirm -S efibootmgr
    if [[ $? == 0 ]]; then
      break
    else
      :
    fi
  done
fi

clear

install_dir="$mount_path/usr/lib/initcpio/install"
hooks_dir="$mount_path/usr/lib/initcpio/hooks"

# Duplicate encrypt hook
echo "Duplicating encrypt hook"
echo "Duplicating encrypt hook"
cp "$install_dir"/encrypt "$install_dir"/encrypt2
cp "$hooks_dir"/encrypt   "$hooks_dir"/encrypt2
sed -i "s@cryptdevice@cryptdevice2@g" "$install_dir"/encrypt2
sed -i "s@cryptkey@cryptkey2@g"       "$install_dir"/encrypt2
sed -i "s@cryptdevice@cryptdevice2@g" "$hooks_dir"/encrypt2
sed -i "s@cryptkey@cryptkey2@g"       "$hooks_dir"/encrypt2

# Add custom hook to close boot partition
custom_install_hooks_dir="hooks_install"
custom_runtime_hooks_dir="hooks_runtime"
custom_hook_name="closeboot"

echo "Installing custom hook to close boot partition opened by cryptsetup"
cp "$custom_install_hooks_dir"/"$custom_hook_name"    "$install_dir"
cp "$custom_runtime_hooks_dir"/"$custom_hook_name"    "$hooks_dir"
sed -i "s@MAPPER_NAME_BOOT_DUMMY@$mapper_name_boot@g" "$hooks_dir"/"$custom_hook_name"

wait_and_clear 2

# Setup config
echo "Updating mkinitcpio.conf"
modules="ext4"
hooks="base udev autodetect modconf block encrypt encrypt2 closeboot filesystems keyboard fsck"
sed -i "s@^HOOKS=.*@HOOKS=\"$hooks\"@g" "$mount_path"/etc/mkinitcpio.conf

wait_and_clear 2

echo "Recreating image"
arch-chroot "$mount_path" mkinitcpio -p linux-grsec

wait_and_clear 2

echo "Updating grub config"
echo "GRUB_ENABLE_CRYPTODISK=y" >> "$mount_path"/etc/default/grub

grub_cmdline_linux_default="quiet cryptdevice=UUID=$USB_KEY_BOOT_UUID:$mapper_name_boot cryptdevice2=UUID=$SYS_PART_UUID:$mapper_name_sys cryptkey2=/dev/mapper/$mapper_name_boot:ext4:/$key_file_name"

sed -i "s@^GRUB_CMDLINE_LINUX_DEFAULT=.*@GRUB_CMDLINE_LINUX_DEFAULT=\"$grub_cmdline_linux_default\"@g" "$mount_path"/etc/default/grub

wait_and_clear 2

# Install grub and required files
echo "Install grub onto USB key"
if $efi_mode; then
  echo "Reset ESP directory"
  rm -rf "$mount_path"/boot/efi
  mkdir "$mount_path"/boot/efi

  echo "Mounting ESP partition"
  mount "$USB_KEY_ESP" "$mount_path"/boot/efi

  arch-chroot "$mount_path" grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
else
  arch-chroot "$mount_path" grub-install --target=i386-pc --boot-directory=/boot $USB_KEY
fi

echo "Generating grub configuration file"
arch-chroot "$mount_path" grub-mkconfig -o /boot/grub/grub.cfg

wait_and_clear 2

# Prepare USB key mounting/unmounting scripts and copy into new system
echo "Generating USB key mounting and unmounting scripts"
mount_script_name="usb_key_mount.sh"
mount_script_path="$mount_path"/root/"$mount_script_name"
cp crypt_disk_mount_template "$mount_script_path"
chown root:root "$mount_script_path"
if $efi_mode; then
  sed -i "s@EFI_MODE_DUMMY@true@g" "$mount_script_path"
  sed -i "s@USB_KEY_ESP_UUID_DUMMY@$USB_KEY_ESP_UUID@g" "$mount_script_path"
else
  sed -i "s@EFI_MODE_DUMMY@false@g" "$mount_script_path"
fi
sed -i "s@USB_KEY_BOOT_UUID_DUMMY@$USB_KEY_BOOT_UUID@g" "$mount_script_path"
sed -i "s@MAPPER_NAME_BOOT_DUMMY@$mapper_name_boot@g" "$mount_script_path"
chmod u=rx "$mount_script_path"
chmod g=rx "$mount_script_path"
chmod o=   "$mount_script_path"

umount_script_name="usb_key_umount.sh"
umount_script_path="$mount_path"/root/"$umount_script_name"
cp crypt_disk_umount_template "$umount_script_path"
chown root:root "$umount_script_path"
if $efi_mode; then
  sed -i "s@EFI_MODE_DUMMY@true@g" "$umount_script_path"
  sed -i "s@USB_KEY_ESP_UUID_DUMMY@$USB_KEY_ESP_UUID@g" "$umount_script_path"
else
  sed -i "s@EFI_MODE_DUMMY@false@g" "$umount_script_path"
fi
sed -i "s@USB_KEY_BOOT_UUID_DUMMY@$USB_KEY_BOOT_UUID@g" "$umount_script_path"
sed -i "s@MAPPER_NAME_BOOT_DUMMY@$mapper_name_boot@g" "$umount_script_path"
chmod u=rx "$umount_script_path"
chmod g=rx "$umount_script_path"
chmod o=   "$umount_script_path"

wait_and_clear 2

# Generate saltstack execution script
echo "Generating saltstack execution script"
salt_exec_script_name="salt_exec.sh"
salt_exec_script_path="$mount_path"/root/"$salt_exec_script_name"
cp salt_stack_execute_template "$salt_exec_script_path"
chown root:root "$salt_exec_script_path"
chmod u=rx "$salt_exec_script_path"
chmod g=rx "$salt_exec_script_path"
chmod o=   "$salt_exec_script_path"

wait_and_clear 2

# Copy note over
echo "Generating setup note"
llsh_setup_note_name="llsh_setup_note"
llsh_setup_note_path="$mount_path"/root/"$llsh_setup_note_name"
cp llsh_setup_note_template "$llsh_setup_note_path"
chown root:root "$llsh_setup_note_path"
sed -i "s@SALT_STACK_EXEC_SCRIPT_DUMMY@$salt_exec_script_name@g" "$llsh_setup_note_path"
sed -i "s@USB_KEY_MOUNT_SCRIPT_DUMMY@$mount_script_name@g" "$llsh_setup_note_path"
sed -i "s@USB_KEY_UMOUNT_SCRIPT_DUMMY@$umount_script_name@g" "$llsh_setup_note_path"
chmod u=rx "$llsh_setup_note_path"
chmod g=rx "$llsh_setup_note_path"
chmod o=   "$llsh_setup_note_path"

wait_and_clear 2

# Install saltstack
while true; do
  echo "Installing saltstack"
  arch-chroot "$mount_path" pacman --noconfirm -S salt-zmq
  if [[ $? == 0 ]]; then
    break
  else
    :
  fi
done

wait_and_clear 2

# Setup saltstack
echo "Updating saltstack config"
sed -i "s@#file_client: remote@file_client: local@g" "$mount_path"/etc/salt/minion

wait_and_clear 2

# Copy saltstack files
saltstack_files_path="../saltstack"
echo "Copying saltstack files over to system"
cp -r "$saltstack_files_path"/*   "$mount_path"/srv

wait_and_clear 2

end=false
while ! $end; do
  echo -n "Do you want to execute saltstack right now? y/n : "
  read ans
  if [[ $ans == "y" ]]; then
    run_salt=true
    echo "You entered yes"
  elif [[ $ans == "n" ]]; then
    run_salt=false
    echo "You entered no"
  else
    echo -e $INVALID_ANS
    continue
  fi

  while true; do
    echo -n "Is this correct? y/n : "
    read ans
    if [[ $ans == "y" ]]; then
      end=true
      break
    elif [[ $ans == "n" ]]; then
      end=false
      break
    else
      echo -e $INVALID_ANS
    fi
  done
done

if $run_salt; then
  echo "Executing salt for final setup"
  arch-chroot "$mount_path" salt-call --local state.apply

  wait_and_clear 2
fi

clear

end=false
while ! $end; do
  echo -n "Do you want to close the disks and USB key? y/n : "
  read ans
  if [[ $ans == "y" ]]; then
    close_disks=true
    echo "You entered yes"
  elif [[ $ans == "n" ]]; then
    close_disks=false
    echo "You entered no"
  else
    echo -e $INVALID_ANS
    continue
  fi

  while true; do
    echo -n "Is this correct? y/n : "
    read ans
    if [[ $ans == "y" ]]; then
      end=true
      break
    elif [[ $ans == "n" ]]; then
      end=false
      break
    else
      echo -e $INVALID_ANS
    fi
  done
done

if $close_disks; then
  umount -R /mnt
  cryptsetup luksClose /dev/mapper/"$mapper_name_boot"
  cryptsetup luksClose /dev/mapper/"$mapper_name_sys"
fi

clear

# Restart
end=false
while ! $end; do
  echo -n "Do you want to restart? y/n : "
  read ans
  if [[ $ans == "y" ]]; then
    shutdown_system=true
    echo "You entered yes"
  elif [[ $ans == "n" ]]; then
    shutdown_system=false
    echo "You entered no"
  else
    echo -e $INVALID_ANS
    continue
  fi

  while true; do
    echo -n "Is this correct? y/n : "
    read ans
    if [[ $ans == "y" ]]; then
      end=true
      break
    elif [[ $ans == "n" ]]; then
      end=false
      break
    else
      echo -e $INVALID_ANS
    fi
  done
done

if $shutdown_system; then
  echo "Restarting system in 1 minute"
  shutdown -t 1 -r now
fi
