#!/bin/bash

INVALID_ANS="Invalid answer"
NO_COMMAND="Command not found"

# Notes
echo "Notes:"
echo "  Please note that you need to have an external USB drive for this installation"
echo "Press enter to continue"
read

# Show requirement
echo "Requirements:"
echo "  The main system partition should be setup already(no need to be formatted)"
echo ""
echo "Please fulfill the requirements above if any is missing,"
echo "and press enter after partitioning to continue"
read

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


# Choose editor
end=0
while [[ $end == 0 ]]; do
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
        end=1
        break
      elif [[ $ans == "n"  ]]; then
        end=0
        break
      else
        echo -e $INVALID_ANS
      fi
    done
  else 
    echo -e $NO_COMMAND
  fi
done

# Configure mirrorlist
mirrorlist_path="/etc/pacman.d/mirrorlist"
end=0
while [[ $end == 0 ]]; do
  echo "Stage : configure mirrorlist"

  echo "Press enter to continue"
  read ans

  while true; do
    $EDITOR $mirrorlist_path

    echo -n "Finished editing? y/n : "
    read ans
    if   [[ $ans == "y" ]]; then
      end=1
      break
    elif [[ $ans == "n" ]]; then
      end=0
      break
    else
      echo -e $INVALID_ANS
    fi
  done
done

# choose system partition
end=0
while [[ $end == 0 ]]; do
  echo "Stage : choose system partition"

  echo -n "Please specify a partition to use : "
  read SYS_PART

  if [ -b $SYS_PART ]; then
    echo "System parition picked :" $SYS_PART
    while true; do
      echo -n "Is this correct? y/n : "
      read ans
      if   [[ $ans == "y" ]]; then
        end=1
        break
      elif [[ $ans == "n" ]]; then
        end=0
        break
      else
        echo -e $INVALID_ANS
      fi
    done
  else
    echo "Partition does not exist"
  fi
done

# Setup encryption and USB key
end=0
while [[ $end == 0 ]]; do
  echo "Stage : setup encryption and USB key"
  echo "Warning : data on USB key will be lost"

  echo -n "Please specify the USB key device"
  read USB_KEY

  if [ -b "$USB_KEY" ]; then
    echo "Device picked :" "$USB_KEY"
    while true; do
      echo -n "Is this correct? y/n : "
      read ans
      if   [[ $ans == "y" ]]; then
        end=1
        break
      elif [[ $ans == "n" ]]; then
        end=0
        break
      else
        echo -e $INVALID_ANS
      fi
    done
  else
    echo "Device does not exist"
  fi
done

## Partition the USB key
efi_firmware_path="/sys/firmware/efi"
echo "Preparing USB key"
if [ -e $efi_firmware_path ]; then
  echo "System is in UEFI mode"

  echo "Creating GPT partition table"
  parted "$USB_KEY" mklabel gpt 2>/dev/null
else
  echo "System is in BIOS mode"

  echo "Creating MBR partition table"
  parted "$USB_KEY" mklabel msdos 2>/dev/null
fi

echo "Wiping paritioning info"
dd if=/dev/zero of="$USB_KEY" bs=512 count=2

echo "Creating boot partition"
parted -a optimal "$USB_KEY" mkpart primary 0% 33%

# Install base system

# Setup GRUB

# Copy USB key mounting/unmounting scripts into new system

# Basic setup of system

# Copy saltstack files

# Execute salt for final setup

# Restart
