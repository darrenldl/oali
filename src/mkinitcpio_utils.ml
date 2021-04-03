let gen_mkinitcpio_hooks ~(encrypt_sys : Disk_layout.sys_part_enc_choice) ~use_lvm =
  List.filter_map
    (fun x -> x)
    [
      Some "base";
      Some "udev";
      Some "autodetect";
      Some "keyboard";
      Some "keymap";
      Some "consolefont";
      Some "modconf";
      Some "block";
      (match encrypt_sys with
       | `None -> None
       | `Passphrase | `Keyfile -> Some "encrypt");
      (if use_lvm then Some "lvm2" else None);
      Some "filesystems";
      Some "fsck";
    ]
