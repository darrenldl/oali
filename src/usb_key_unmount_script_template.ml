let gen ~encrypt ~is_efi_mode =
  Printf.sprintf
    {|
#!/bin/bash
encrypt=%b
efi_mode=%b
mapper_name_boot=%s
efi_dir=%s
boot_dir=%s
    |}
    encrypt is_efi_mode Config.boot_mapper_name Config.efi_dir Config.boot_dir
  ^ {|
if $efi_mode; then
  echo "Umounting EFI partition"
  umount "$efi_dir"
fi

echo "Unmounting boot partition"
umount "$boot_dir"

if $encrypt; then
  echo "Closing boot partition"
  cryptsetup close /dev/mapper/"$mapper_name_boot"
fi

echo "USB key unmounted successfully"
|}
