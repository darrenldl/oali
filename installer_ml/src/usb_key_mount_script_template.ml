let gen ~use_encrypt ~is_efi_mode ~esp_uuid ~boot_uuid =
  Printf.sprintf
    {|#!/bin/bash
encrypt=%b
efi_mode=%b
usb_key_esp_uuid=%s
usb_key_boot_uuid=%s
mapper_name_boot=%s

while true; do
  echo "Looking for encrypted boot"

  if $encrypt; then
    if [ -b /dev/disk/by-uuid/"$usb_key_boot_uuid" ]; then
      echo "Unlocking boot partition"
      cryptsetup open --type luks /dev/disk/by-uuid/"$usb_key_boot_uuid" "$mapper_name_boot"
      if [[ $? == 0 ]]; then
        break
      else
        :
      fi
    else
      echo "Boot partition not found"
    fi
  fi

  echo -n "Do you want to exit the script? y/N : "
  read ans
  if [[ $ans == "y" ]]; then
    exit 1
  else
    :
  fi
done

echo "Mounting boot partition"
if $encrypt; then
  mount /dev/mapper/"$mapper_name_boot" /boot
else
  mount /dev/disk/by-uuid/"$usb_key_boot_uuid" /boot
fi

if $efi_mode; then
  while true; do
    echo "Looking for ESP partition"

    if [ -b /dev/disk/by-uuid/"$usb_key_esp_uuid" ]; then
      break
    else
      echo "ESP partition not found"
    fi

    echo -n "Do you want to exit the script? y/N : "
    read ans
    if [[ $ans == "y" ]]; then
      exit
    else
      :
    fi
  done

  echo "Mounting EFI partition"
  mount /dev/disk/by-uuid/"$usb_key_esp_uuid" /efi
fi

echo "USB key mounted successfully"
|}
    use_encrypt is_efi_mode
    (Option.value ~default:"" esp_uuid)
    boot_uuid Config.boot_mapper_name
