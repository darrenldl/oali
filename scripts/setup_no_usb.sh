#!/bin/bash
#
# Author : Darren Ldl <darrenldldev@gmail.com>
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

INVALID_ANS="Invalid answer"
NO_COMMAND="Command not found"

ask_ans() {
  if   (( $# <= 1 )); then
    echo "Too few parameters"
    exit
  elif (( $# >= 2 )); then
    ret_var=$1
    message=$2
  fi

  echo -ne "$message"" : "
  read ans

  eval "$ret_var=$ans"
}

ask_yn() {
  if   (( $# <= 1 )); then
    echo "Too few parameters"
    exit
  elif (( $# >= 2 )); then
    ret_var=$1
    message=$2
  fi

  while true; do
    echo -ne "$message"" y/n : "
    read ans
    if   [[ $ans == "y" ]]; then
      eval "$ret_var=true"
      break
    elif [[ $ans == "n" ]]; then
      eval "$ret_var=false"
      break
    else
      echo -e $INVALID_ANS
    fi
  done
}

ask_if_correct() {
  ask_yn $1 "Is this correct?"
}

comple() {
  if $(eval echo '$'$1); then
    eval "$2=false"
  else
    eval "$2=true"
  fi
}

flip_ans() {
  if $(eval echo '$'$1); then
    eval "$1=false"
  else
    eval "$1=true"
  fi
}

default_wait=1
wait_and_clear() {
  if [[ $# == 0 ]]; then
    sleep $default_wait
  else
    sleep $1
  fi
  clear
}

tell_press_enter() {
  echo "Press enter to continue"
  read
}

default_retries=5
install_with_retries() {
  if   [[ $# == 0 ]]; then
    echo "Too few parameters"
    exit
  elif [[ $# == 1 ]]; then
    package_name=$1
    retries=$default_retries
    retries_left=$default_retries
  elif (( $# >= 2 )); then
    package_name=$1
    retries=$2
    retries_left=$2
  fi

  while true; do
    echo "Installing ""$package_name"" package"
    arch-chroot "$mount_path" pacman --noconfirm -S $package_name
    if [[ $? == 0 ]]; then
      break
    else
      retries_left=$[$retries_left-1]
    fi

    if [[ $retries_left == 0 ]]; then
      echo "Package install failed ""$retries"" times"
      ask_yn change_name "Do you want to change package name before continuing retry?"

      if $change_name; then
        ask_new_name_end=false
        while ! $ask_new_name_end; do
          echo "Original package name :" $package_name
          echo "Please enter new package name : "
          read package_name

          ask_if_correct ask_new_name_end
        done
      fi

      retries_left=$retries
    fi
  done
}

tell_read_note() {
cat <<READNOTEEOF

===== IMPORTANT =====
Please read over the setup note that this setup script has generated for you
The setup note is stored as "/root/llsh_pack/$llsh_setup_note_name" in your system

The setup note contains important information of the other helper scripts that have been generated for you
=====================

READNOTEEOF

  tell_press_enter
}

clear

# Notes
echo "Notes:"
echo "  Please note that you need to have an external USB drive for this installation"
tell_press_enter

clear

# Show requirement
cat <<REQUIREEOF
Requirements:
    The main system partition should be setup already (no need to be formatted)

    Have the USB key with you (data will be lost)

    Working internet connection

    Previously (properly) prepared keyfile (optional - highly recommended however)

REQUIREEOF

echo "Please fulfill the requirements above if any is missing,"
echo "and press enter after partitioning to continue"
read

clear

# Show stages
cat <<STAGEEOF
Stages:
    update time
    choose editor
    configure mirrorlist
    choose boot partition
    choose system partition
    setup encryption
    set hostname
    set locale
    update package database
    install system
    setup GRUB
    setup hooks
    setup mkinitcpio config
    setup GRUB config
    install GRUB
    generate USB key mounting/unmounting scripts
    generate saltstack execution script
    generate setup note
    add user
    install saltstack             (optional)
      |-> copy saltstack files          (optional)
      |-> execute salt for final setup  (optional)
    close all partitions          (optional)
    restart                       (optional)

STAGEEOF

echo "Press enter to continue"
read

clear

# Grab path to self
pushd `dirname $0` > /dev/null
path_to_self=$(pwd -P)
popd > /dev/null

# Update time
echo "Updating time"
timedatectl set-ntp true

echo ""
echo -n "Current time : "
date

wait_and_clear 5

# Choose editor
echo "Choose editor"
echo ""

end=false
while ! $end; do
  EDITOR=""
  echo -n "Please specifiy a text editor to use : "
  read EDITOR

  if hash $EDITOR &>/dev/null; then
    echo "Editor selected :" $EDITOR
    ask_if_correct end
  else
    echo -e $NO_COMMAND
  fi
done

clear

# Configure mirrorlist
echo "Configure mirrorlist"
echo ""

tell_press_enter

mirrorlist_path="/etc/pacman.d/mirrorlist"
end=false
while ! $end; do
  $EDITOR $mirrorlist_path

  clear

  ask_yn end "Finished editing?"
done

clear

# choose boot partition
echo "Choose boot partitions"
echo ""

end=false
while ! $end; do
    ask_ans BOOT_PART "Please specify a partition to use"

    if [ -b "$BOOT_PART" ]; then
        echo "Boot parition picked :" "$BOOT_PART"
        ask_if_correct end
    else
        echo "Partition does not exist"
    fi
done

end=false
while ! $end; do
    ask_ans BOOT_PART "Please specify the ESP partition"

    if [ -b "$ESP_PART" ]; then
        echo "ESP parition picked :" "$ESP_PART"
        ask_if_correct end
    else
        echo "Partition does not exist"
    fi
done

BOOT_DISK=$(echo "$BOOT_PART" | tr -d 0-9)

clear

# choose system partition
echo "Choose system partition"
echo ""

end=false
while ! $end; do
  ask_ans SYS_PART "Please specify a partition to use"

  if [ -b "$SYS_PART" ]; then
    echo "System parition picked :" "$SYS_PART"
    ask_if_correct end
  else
    echo "Partition does not exist"
  fi
done

clear

# Setup encryption
echo "Setup encryption"
echo ""

clear

sys_part_luks_iter_time_millisec=2000
while true; do
  echo "The current iteration time for the SYSTEM partition in millisecond is :" $sys_part_luks_iter_time_millisec
  end=false
  while ! $end; do
    ask_yn adjust_millisec "Do you want to adjust the iteration time?"

    ask_if_correct end
  done

  if $adjust_millisec; then
    while true; do
      ask_end=false
      while ! $ask_end; do
        ask_ans new_millisec "Please enter new iteration time in millisecond"

        ask_if_correct ask_end
      done

      if (( 0 < $new_millisec )); then
        sys_part_luks_iter_time_millisec=$new_millisec
        break
      else
        echo "Time invalid"
      fi
    done
  else
    break
  fi
done

clear

# ask for hostname
echo "Choose hostname"
echo ""

end=false
while ! $end; do
  ask_ans host_name "Please enter hostname"

  echo "You entered : " $host_name
  ask_if_correct end
done

clear

# Ask if want to use hardened kernel
echo "Choose whether to install hardened kernel or not"
echo ""

end=false
while ! $end; do
  ask_yn use_hardened "Do you want to install hardened kernel?"

  ask_if_correct end
done

if $use_hardened; then
  end=false
  while ! $end; do
    ask_yn remove_vanilla "Do you want to remove vanilla kernel?"

    ask_if_correct end
  done
else
  remove_vanilla=false
fi

clear

if $use_hardened; then
  end=false
  while ! $end; do
    ask_yn set_hardened_as_default "Do you want to set GRUB default boot entry to the hardened kernel?"
    ask_if_correct end
  done
fi

clear

# Ask if want to use SaltStack
end=false
while ! $end; do
  ask_yn use_salt "Do you want to use saltstack for further installation?"

  ask_if_correct end
done

clear

sys_part_luks_cipher=aes-xts-plain64
sys_part_luks_key_size=512
sys_part_luks_hash=sha512

# Encrypt main system partition
while true; do
  echo "Encrypting system partition"
  cryptsetup luksFormat -y                                            \
                        --cipher    $sys_part_luks_cipher             \
                        --key-size  $sys_part_luks_key_size           \
                        --iter-time $sys_part_luks_iter_time_millisec \
                        --hash      $sys_part_luks_hash               \
                        $SYS_PART
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

echo "Unlocking system partition"
cryptsetup open --type luks                 \
                $SYS_PART                   \
                "$mapper_name_sys"

wait_and_clear

echo "Formatting system partition"
mkfs.ext4 /dev/mapper/"$mapper_name_sys"

wait_and_clear 2

echo "Mounting system partition"
mount /dev/mapper/"$mapper_name_sys" "$mount_path"

echo "Creating boot directory"
mkdir -p "$mount_path"/boot

wait_and_clear 2

echo "Formatting boot partition"
mkfs.ext4 "$BOOT_PART"

wait_and_clear 2

echo "Mounting boot partition"
mount "$BOOT_PART" "$mount_path"/boot

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

echo "Generating fstab"
mkdir -p "$mount_path"/etc
genfstab -U "$mount_path" >> "$mount_path"/etc/fstab

wait_and_clear 2

# Setup hostname
echo "Setting up hostname"
echo $host_name > "$mount_path"/etc/hostname

wait_and_clear 2

echo "Setting locale"
sed -i "s@#en_US.UTF-8 UTF-8@en_US.UTF-8 UTF-8@g" "$mount_path"/etc/locale.gen
sed -i "s@#en_DK.UTF-8 UTF-8@en_DK.UTF-8 UTF-8@g" "$mount_path"/etc/locale.gen
echo "LANG=en_US.UTF-8"    >  "$mount_path"/etc/locale.conf
echo "LC_ALL=en_US.UTF-8"  >> "$mount_path"/etc/locale.conf
echo "LC_TIME=en_DK.UTF-8" >> "$mount_path"/etc/locale.conf
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

# Install prerequisites for wifi-menu
while true; do
  echo "Installing prerequisites for wifi-menu"
  arch-chroot "$mount_path" pacman --noconfirm -S dialog wpa_supplicant
  if [[ $? == 0 ]]; then
    break
  else
    :
  fi
done

clear

if $use_hardened; then
  if $remove_vanilla; then
    # Remove vanilla kernel
    while true; do
      echo "Removing vanilla kernel"
      arch-chroot "$mount_path" pacman --noconfirm -R linux
      if [[ $? == 0 ]]; then
        break
      else
        :
      fi
    done
  fi

  wait_and_clear

  install_with_retries linux-hardened

  install_with_retries linux-hardened-headers

  wait_and_clear
fi

clear

# Setup GRUB
install_with_retries "grub"

if $efi_mode; then
  install_with_retries "efibootmgr"
  install_with_retries "efitools"
fi

clear

# Setup config
echo "Updating mkinitcpio.conf"
modules="ext4"
hooks="base udev autodetect modconf block encrypt closeboot filesystems keyboard fsck"
sed -i "s@^HOOKS=.*@HOOKS=\"$hooks\"@g" "$mount_path"/etc/mkinitcpio.conf

wait_and_clear 2

echo "Updating grub config"
etc_default_grub_path="$mount_path"/etc/default/grub

# Check if GRUB_ENABLE_CRYPTODISK is specified in grub file first
res=$(grep "GRUB_ENABLE_CRYPTODISK" $etc_default_grub_path)

if [[ $res == "" ]]; then
  # Not specified in file at all
  echo "GRUB_ENABLE_CRYPTODISK=y" >> $etc_default_grub_path
else
  # Check if specified as comment or as a configured option
  res=$(grep "^GRUB_ENABLE_CRYPTODISK" $etc_default_grub_path)

  if [[ $res == "" ]]; then     # not configured
    sed -i "s@#GRUB_ENABLE_CRYPTODISK.*@GRUB_ENABLE_CRYPTODISK=y@g" $etc_default_grub_path
  else                          # configured to whatever
    sed -i "s@GRUB_ENABLE_CRYPTODISK.*@GRUB_ENABLE_CRYPTODISK=y@g" $etc_default_grub_path
  fi
fi

grub_cmdline_linux_default="quiet cryptdevice=UUID=$SYS_PART_UUID:$mapper_name_sys"

sed -i "s@^GRUB_CMDLINE_LINUX_DEFAULT=.*@GRUB_CMDLINE_LINUX_DEFAULT=\"$grub_cmdline_linux_default\"@g" "$mount_path"/etc/default/grub

if $use_hardened; then
  if $set_hardened_as_default; then
    sed -i "s@GRUB_DEFAULT=.*@GRUB_DEFAULT=\"Advanced options for Arch Linux>Arch Linux, with Linux linux-hardened\"@" $etc_default_grub_path
  fi
fi

wait_and_clear 2

# Install grub and required files
echo "Install grub onto USB key"
if $efi_mode; then
  echo "Reset ESP directory"
  rm -rf "$mount_path"/boot/efi
  mkdir -p "$mount_path"/boot/efi

  echo "Mounting ESP partition"
  mount "$ESP_PART" "$mount_path"/boot/efi

  arch-chroot "$mount_path" grub-install --removable --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
else
  arch-chroot "$mount_path" grub-install --removable --target=i386-pc --boot-directory=/boot $BOOT_DISK
fi

echo "Generating grub configuration file"
arch-chroot "$mount_path" grub-mkconfig -o /boot/grub/grub.cfg

wait_and_clear 2

# Setup files in /root directory
echo "Setting up files in /root directory"
llsh_files_dir_name="llsh_pack"
llsh_files_dir_path="$mount_path"/root/"$llsh_files_dir_name"
mkdir -p "$llsh_files_dir_path"

# Prepare USB key mounting/unmounting scripts and copy into new system
echo "Generating USB key mounting and unmounting scripts"
mount_script_name="usb_key_access_mount.sh"
mount_script_path="$llsh_files_dir_path"/"$mount_script_name"
cp "$path_to_self"/usb_key_access_mount_template "$mount_script_path"
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

umount_script_name="usb_key_access_umount.sh"
umount_script_path="$llsh_files_dir_path"/"$umount_script_name"
cp "$path_to_self"/usb_key_access_umount_template "$umount_script_path"
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

# Prepare safe upgrade script
# echo "Generating safe upgrade script"
# safe_upgrade_script_name="safe_upgrade.sh"
# safe_upgrade_script_path="$mount_path"/root/"$safe_upgrade_script_name"
# cp safe_upgrade_template "$safe_upgrade_script_path"
# chown root:root "$safe_upgrade_script_path"
# sed -i "s@UMOUNT_SCRIPT_NAME_DUMMY@$mount_script_name@g" "$safe_upgrade_script_path"
# chmod u=rx "$safe_upgrade_script_path"
# chmod g=rx "$safe_upgrade_script_path"
# chmod o=   "$safe_upgrade_script_path"

# wait_and_clear 2

# Make directory in encrypted boot partition for USB key resetting scripts
# llsh_usb_key_reset_nonlive_dir=/boot/llsh_usb_key_reset
# llsh_usb_key_reset_live_dir="$mount_path"$llsh_usb_key_reset_nonlive_dir
# echo "Initilising directory for USB key resetting scripts in encrypted boot partition"
# echo ""
# mkdir -p          $llsh_usb_key_reset_live_dir
# chown root:root $llsh_usb_key_reset_live_dir
# chmod u=rwx     $llsh_usb_key_reset_live_dir
# chmod g=rwx     $llsh_usb_key_reset_live_dir
# chmod o=        $llsh_usb_key_reset_live_dir

# Copy usb key reset main script over to encrypted boot partition
# llsh_usb_key_reset_main_name="usb_key_reset_main.sh"
# llsh_usb_key_reset_main_path="$llsh_usb_key_reset_live_dir"/"$llsh_usb_key_reset_main_name"
# echo "Generating main script to be stored in "$llsh_usb_key_reset_nonlive_dir" of actual system (not live)"
# echo ""
# cp usb_key_reset_main_template "$llsh_usb_key_reset_live_dir"
# sed -i "s@@@g"

# Copy usb key reset script loader script to encrypted boot partition
# llsh_usb_key_reset_loader_name="usb_key_reset_loader.sh"
# llsh_usb_key_reset_loader_path="$llsh_usb_key_reset_live_dir"/"$llsh_usb_key_reset_loader_name"
# echo "Generating loader script to be stored in "$llsh_usb_key_reset_nonlive_dir" of actual system (not live)"
# echo ""
# cp usb_key_reset_loader_template "$llsh_usb_key_reset_loader_path"
# sed -i "s@LLSH_USB_KEY_RESET_MAIN_DUMMY@@g"

# wait_and_clear 2

# Copy useradd helper scripts over
echo "Copying useradd helper scripts"
useradd_helper1_name="useradd_helper_as_powerful.sh"
useradd_helper1_path="$llsh_files_dir_path"/"$useradd_helper1_name"
cp "$path_to_self"/useradd_helper_as_powerful.sh "$useradd_helper1_path"
chmod u=rx "$useradd_helper1_path"
chmod g=rx "$useradd_helper1_path"
chmod o=   "$useradd_helper1_path"

useradd_helper2_name="useradd_helper_restricted.sh"
useradd_helper2_path="$llsh_files_dir_path"/"$useradd_helper2_name"
cp "$path_to_self"/useradd_helper_restricted.sh "$useradd_helper2_path"
chmod u=rx "$useradd_helper2_path"
chmod g=rx "$useradd_helper2_path"
chmod o=   "$useradd_helper2_path"

# Copy note over
echo "Generating setup note"
llsh_setup_note_name="llsh_setup_note"
llsh_setup_note_path="$llsh_files_dir_path"/"$llsh_setup_note_name"
cp "$path_to_self"/llsh_setup_note_template "$llsh_setup_note_path"
chown root:root "$llsh_setup_note_path"
# Replace placeholders with actual text
sed -i "s@USB_KEY_MOUNT_SCRIPT_DUMMY@$mount_script_name@g"          "$llsh_setup_note_path"
sed -i "s@USB_KEY_UMOUNT_SCRIPT_DUMMY@$umount_script_name@g"        "$llsh_setup_note_path"
sed -i "s@LLSH_USB_KEY_RESET_DIR_DUMMY@$llsh_usb_key_reset_dir@g"   "$llsh_setup_note_path"
sed -i "s@USERADD_HELPER_AS_POWERFUL_DUMMY@$useradd_helper1_name@g" "$llsh_setup_note_path"
sed -i "s@USERADD_HELPER_RESTRICTED_DUMMY@$useradd_helper2_name@g"  "$llsh_setup_note_path"
chmod u=rx "$llsh_setup_note_path"
chmod g=rx "$llsh_setup_note_path"
chmod o=   "$llsh_setup_note_path"

# Leave a copy in the encrytped boot partition as well
cp "$llsh_setup_note_path" /boot

wait_and_clear 2

echo "Root setup"
echo ""

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

echo "User setup"
echo ""

while true; do
  ask_end=false
  while ! $ask_end; do
    ask_ans user_name "Please enter the user name"
    echo "You entered : " $user_name
    ask_if_correct ask_end
  done

  echo "Adding user"
  arch-chroot "$mount_path" useradd -m "$user_name" -G users,wheel,rfkill
  if [[ $? == 0 ]]; then
    break
  else
    echo "Failed to add user"
    echo "Please check whether the user name is correctly specified and if acceptable by the system"

    tell_press_enter
  fi
done

while true; do
  echo "Setting password for user : " $user_name

  arch-chroot "$mount_path" passwd "$user_name"
  if [[ $? == 0 ]]; then
    break
  else
    echo "Failed to set password"
    echo "Please repeat the procedure"

    tell_press_enter
  fi
done

echo "User :" $user_name "added"

wait_and_clear 2

if $use_salt; then
  # Generate saltstack execution script
  echo "Generating saltstack execution script"
  salt_exec_script_name="salt_exec.sh"
  salt_exec_script_path="$llsh_files_dir_path"/"$salt_exec_script_name"
  cp salt_stack_execute_template "$salt_exec_script_path"
  chown root:root "$salt_exec_script_path"
  sed -i "s@USB_KEY_MOUNT_SCRIPT_DUMMY@$mount_script_name@g" "$salt_exec_script_path"
  sed -i "s@MAPPER_NAME_BOOT_DUMMY@$mapper_name_boot@g" "$salt_exec_script_path"
  chmod u=rx "$salt_exec_script_path"
  chmod g=rx "$salt_exec_script_path"
  chmod o=   "$salt_exec_script_path"

  # Mark script name in setup note
  sed -i "s@SALT_STACK_EXEC_SCRIPT_DUMMY@$salt_exec_script_name@g" "$llsh_setup_note_path"

  wait_and_clear 2

  # Install saltstack
  install_with_retries "salt"

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

  # Customise saltstack files
  echo "Configuring salt files to target user : "$user_name
  sed -i "s@USER_NAME_DUMMY@$user_name@g" "$mount_path"/srv/pillar/user.sls

  wait_and_clear 2
else
  # Mark script not present in setup note
  sed -i "s@SALT_STACK_EXEC_SCRIPT_DUMMY@SaltSatck execution script not installed@g" "$llsh_setup_note_path"
fi

clear

end=false
while ! $end; do
  ask_yn close_disks "Do you want to close the partitions and USB key?"

  ask_if_correct end
done

if $close_disks; then
  umount -R /mnt
  cryptsetup close /dev/mapper/"$mapper_name_boot"
  cryptsetup close /dev/mapper/"$mapper_name_sys"
fi

clear

if $close_disks; then
  # Shut down
  end=false
  while ! $end; do
    ask_yn shutdown_system "Do you want to shut down now?"

    ask_if_correct end
  done

  tell_read_note

  if $shutdown_system; then
    poweroff
  fi
else
  echo "No shutting down will be done by the script since the partitions are not closed"

  tell_read_note

  wait_and_clear 2
fi

cat <<ENDOFEXECEOF

===============

End of execution

===============

ENDOFEXECEOF
