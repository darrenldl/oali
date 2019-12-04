let gen ~encrypt ~is_efi_mode =
  Printf.sprintf
    {|
#!/bin/bash
encrypt=%b
efi_mode=%b
mapper_name_boot=%s

if $efi_mode; then
  echo "Umounting EFI partition"
  umount /efi
fi

echo "Unmounting boot partition"
umount /boot

if $encrypt; then
  echo "Closing boot partition"
  cryptsetup close /dev/mapper/"$mapper_name_boot"
fi

echo "USB key unmounted successfully"
|}
    encrypt is_efi_mode Config.boot_mapper_name
