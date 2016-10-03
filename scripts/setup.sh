#!/bin/bash

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
end=false
while ! $end; do
  echo "Choose editor"
  echo ""

  EDITOR=""
  echo -n "Please specifiy an editor to use : "
  read EDITOR

  if hash $EDITOR 2>/dev/null; then
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

SYS_PART_UUID=$(blkid "$SYS_PART" | sed -n "s@\(.*\)UUID=\"\(.*\)\" TYPE\(.*\)@\2@p")

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
dd if=/dev/zero of="$USB_KEY" bs=512 count=2 2>/dev/null

wait_and_clear 2

if $efi_mode; then
  echo "Creating GPT partition table"
  parted "$USB_KEY" mklabel gpt 2>/dev/null

  echo "Partitioning"
  parted -a optimal "$USB_KEY" mkpart primary fat32  0%  25% 2>/dev/null
  parted -a optimal "$USB_KEY" mkpart primary       25%  50% 2>/dev/null

  parted "$USB_KEY" set 1 boot on 2>/dev/null

  USB_KEY_ESP="$USB_KEY"1
  USB_KEY_BOOT="$USB_KEY"2
else
  echo "Creating MBR partition table"
  parted "$USB_KEY" mklabel msdos 2>/dev/null

  echo "Partitioning"
  parted -a optimal "$USB_KEY" mkpart primary  0%  25% 2>/dev/null

  parted "$USB_KEY" set 1 boot on 2>/dev/null

  USB_KEY_BOOT="$USB_KEY"1
fi

USB_KEY_BOOT_UUID=$(blkid "$USB_KEY_BOOT" | sed -n "s@\(.*\)UUID=\"\(.*\)\" TYPE\(.*\)@\2@p")

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
    ddrescue --force /dev/urandom "$USB_KEY_BOOT" 2>/dev/null
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
  rm "$mount_path"/etc/fstab.pacnew
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
arch-chroot "$mount_path" local-gen
echo "LANG=en_US.UTF-8" > "$mount_path"/etc/locale.conf

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

# Setup config
echo "Updating mkinitcpio.conf"
hooks="base udev autodetect modconf encrypt block filesystems keyboard fsck"
sed -i "s@^HOOKS=.*@HOOKS=\"$hooks\"@g" "$mount_path"/etc/mkinitcpio.conf

wait_and_clear 2

echo "Recreating image"
arch-chroot "$mount_path" mkinitcpio -p linux-grsec

clear

echo "Updating grub config"
echo "GRUB_ENABLE_CRYPTODISK=y" >> "$mount_path"/etc/default/grub

grub_cmdline_linux_default="quiet cryptdevice:/dev/disk/by-uuid/$SYS_PART_UUID:$mapper_name_sys cryptkey:/dev/disk/by-uuid/$USB_KEY_BOOT_UUID:ext4:/$key_file_name"

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

echo "Generate grub configuration file"
arch-chroot "$mount_path" grub-mkconfig -o /boot/grub/grub.cfg

# Prepare USB key mounting/unmounting scripts and copy into new system

# Basic setup of system

# Install saltstack
while true; do
  echo "Installing saltstack"
  arch-chroot "$mount_path" pacman -S salt-zmq
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
cp -r "$saltstack_files_path"/salt   "$mount_path"/srv
cp -r "$saltstack_files_path"/pillar "$mount_path"/srv

wait_and_clear 2

# Execute salt for final setup
echo "Executing salt"
arch-chroot "$mount_path" salt-call --local state.apply

wait_and_clear 2

# Restart
echo "Restarting system in 30 seconds"
sleep 30
shutdown -r now
