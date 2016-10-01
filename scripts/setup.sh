#!/bin/bash

INVALID_ANS="Invalid answer"
NO_COMMAND="Command not found"

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

# Choose editor
end=false
while ! $end; do
  echo "Stage : choose editor"

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
mirrorlist_path="/etc/pacman.d/mirrorlist"
end=false
while ! $end; do
  echo "Stage : configure mirrorlist"

  echo "Press enter to continue"
  read ans

  while true; do
    $EDITOR $mirrorlist_path

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
end=0
while ! $end; do
  echo "Stage : choose system partition"

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
echo "Stage : setup encryption and USB key"
echo "Warning : data on USB key will be lost"

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
dd if=/dev/zero of="$USB_KEY" bs=512 count=2

if efi_mode; then
  echo "Creating GPT partition table"
  parted "$USB_KEY" mklabel gpt 2>/dev/null

  echo "Partitioning"
  parted -a optimal "$USB_KEY" mkpart primary fat32  0%  25%
  parted -a optimal "$USB_KEY" mkpart primary       25%  50%
else
  echo "Creating MBR partition table"
  parted "$USB_KEY" mklabel msdos 2>/dev/null

  echo "Partitioning"
  parted -a optimal "$USB_KEY" mkpart primary  0%  25%
fi

clear

end=false
while ! end; do
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
    echo "Is this correct? y/n : "
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

if rand_wipe; then
  echo "Ovewriting partitions"

  if efi_mode; then
    ddrescue --force /dev/urandom "$USB_KEY"2 2>/dev/null
  else
    ddrescue --force /dev/urandom "$USB_KEY"1 2>/dev/null
  fi
fi

clear

echo "You will be required to enter passphrase for USB key in following section"
if efi_mode; then
  cryptsetup 
else
fi

# Install base system

# Setup GRUB

# Copy USB key mounting/unmounting scripts into new system

# Basic setup of system

# Copy saltstack files

# Execute salt for final setup

# Restart
