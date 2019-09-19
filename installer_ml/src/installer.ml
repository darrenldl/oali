open Proc_utils
open Misc_utils

let () =
  let config = Task_config.create () in
  let task_book = Task_book.make config in
  let reg ~name task = Task_book.register task_book ~name task in
  reg ~name:"ls" (fun config ->
      let stdin, f = Proc_utils.exec_ret_with_stdin "ls" in
      output_string stdin "abcd";
      let res = f () in
      print_endline "done";
      List.iter print_endline res.stdout;
      config);
  reg ~name:"Update time" (fun config ->
      exec "timedatectl set-ntp true";
      config);
  reg ~name:"Pick editor" (fun config ->
      let editor =
        retry (fun () ->
            let editor =
              ask_string
                ~is_valid:(fun s -> s <> "")
                "Please enter editor command"
            in
            try
              exec (Printf.sprintf "hash %s" editor);
              confirm_answer_is_correct_end_retry ~ret:editor
            with Exec_fail _ ->
              print_endline
                "Failed to find editor, please pick a different one";
              Retry)
      in
      {config with editor = Some editor});
  reg ~name:"Configure mirrorlist" (fun config ->
      let editor = Option.get config.editor in
      Printf.printf "Editor %s will be used for editing mirror list\n" editor;
      tell_press_enter ();
      retry (fun () ->
          exec_no_capture (Printf.sprintf "%s /etc/pacman.d/mirrorlist" editor);
          ask_yn_end_retry ~ret:() "Finished editing?");
      config);
  reg ~name:"Setting hostname" (fun config ->
      let hostname =
        ask_string_confirm ~is_valid:(fun x -> x <> "") "Hostname"
      in
      {config with hostname = Some hostname});
  reg ~name:"Pick whether to encrypt" (fun config ->
      let encrypt = ask_yn "Enable encryption?" = Yes in
      {config with encrypt = Some encrypt});
  reg ~name:"Pick disk layout choice" (fun config ->
      let open Disk_layout in
      let choices =
        [ ("single disk", Single_disk)
        ; ( "system partition + boot partition + maybe EFI partition"
          , Sys_part_plus_boot_plus_maybe_EFI )
          (* ; ( "system partition + boot stuff on external USB drive"
           *   , Sys_part_plus_usb_drive ) *)
        ]
      in
      let choice_num = pick_choice (List.map (fun (x, _) -> x) choices) in
      let choice = (fun (_, y) -> y) (List.nth choices choice_num) in
      {config with disk_layout_choice = Some choice});
  reg ~name:"Checking if in EFI mode" (fun config ->
      let is_efi_mode = Sys.file_exists "/sys/firmware/efi" in
      {config with is_efi_mode = Some is_efi_mode});
  reg ~name:"Configure disk setup parameters" (fun config ->
      let open Disk_layout in
      let encrypt = Option.get config.encrypt in
      let is_efi_mode = Option.get config.is_efi_mode in
      if is_efi_mode then
        print_boxed_msg
          "System is in EFI mode, launching EFI partition selection menu"
      else
        print_boxed_msg
          "System is in BIOS mode, EFI partition selection skipped";
      match Option.get config.disk_layout_choice with
      | Single_disk ->
        let disks = Disk_utils.list_disks () in
        if List.length disks = 0 then
          failwith
            "Not enough disks found, please make sure you have connected at \
             least one disk";
        let disk =
          retry (fun () ->
              let disk_index = pick_choice ~header:"Disks" disks in
              let disk = List.nth disks disk_index in
              ask_yn_end_retry ~ret:disk
                (Printf.sprintf
                   "Partition table of %s will be wiped if you proceed, is \
                    it the right disk?"
                   disk))
        in
        (* reset partition table *)
        Printf.printf "Wiping partition table of %s" disk;
        exec (Printf.sprintf "dd if=/dev/zero of=%s bs=512 count=2" disk);
        (* create partition table *)
        if is_efi_mode then (
          print_endline "Creating GPT partition table";
          exec (Printf.sprintf "parted %s mklabel gpt" disk) )
        else (
          print_endline "Creating MBR partition table";
          exec (Printf.sprintf "parted %s mklabel msdos" disk) );
        (* partitioning *)
        print_endline "Partitioning";
        let disk_size_MiB = Disk_utils.disk_size disk / 1024 / 1024 in
        let boot_part_size_MiB = 500 in
        let boot_part_perc = boot_part_size_MiB * 100 / disk_size_MiB in
        if is_efi_mode then (
          let esp_part_size_MiB = 550 in
          let esp_part_perc = esp_part_size_MiB * 100 / disk_size_MiB in
          let esp_part_beg_perc = 0 in
          let esp_part_end_perc = esp_part_perc in
          let boot_part_beg_perc = esp_part_end_perc in
          let boot_part_end_perc = boot_part_beg_perc + boot_part_perc in
          exec
            (Printf.sprintf "parted -a optimal %s mkpart primary %d%% %d%%"
               disk esp_part_beg_perc esp_part_end_perc);
          exec
            (Printf.sprintf "parted -a optimal %s mkpart primary %d%% %d%%"
               disk boot_part_beg_perc boot_part_end_perc);
          exec
            (Printf.sprintf "parted -a optimal %s mkpart primary %d%% %d%%"
               disk boot_part_end_perc 50);
          exec (Printf.sprintf "parted %s set 1 boot on" disk);
          let esp_part_path = Printf.sprintf "%s1" disk in
          let boot_part_path = Printf.sprintf "%s2" disk in
          let sys_part_path = Printf.sprintf "%s3" disk in
          let esp_part = Some (make_esp_part esp_part_path) in
          let boot_part = make_boot_part encrypt boot_part_path in
          let sys_part = make_sys_part encrypt sys_part_path in
          let disk_layout = make_layout ~esp_part ~boot_part ~sys_part in
          {config with disk_layout = Some disk_layout} )
        else
          let boot_part_end_perc = boot_part_perc in
          exec
            (Printf.sprintf "parted -a optimal %s mkpart primary 0%% %d%%"
               disk boot_part_end_perc);
          exec
            (Printf.sprintf "parted -a optimal %s mkpart primary %d%% %d%%"
               disk boot_part_end_perc 50);
          let boot_part_path = Printf.sprintf "%s1" disk in
          let sys_part_path = Printf.sprintf "%s2" disk in
          let boot_part = make_boot_part encrypt boot_part_path in
          let sys_part = make_sys_part encrypt sys_part_path in
          let disk_layout =
            make_layout ~esp_part:None ~boot_part ~sys_part
          in
          {config with disk_layout = Some disk_layout}
      | Sys_part_plus_boot_plus_maybe_EFI ->
        let parts = Disk_utils.list_parts () in
        if
          (is_efi_mode && List.length parts < 3)
          || ((not is_efi_mode) && List.length parts < 2)
        then
          failwith
            "Not enough partitions found, please make sure partitioning was \
             done correctly";
        let disk_part_tree = Disk_part_tree.of_parts parts in
        let disk_part_tree, esp_part_path =
          if is_efi_mode then
            let disk_index, part_index =
              pick_choice_grouped
                ~first_header:"Select disk containing the EFI partition"
                ~second_header:"Select EFI partition" disk_part_tree
            in
            ( Disk_part_tree.remove_part_by_index ~disk_index ~part_index
                disk_part_tree
            , Some
                (Disk_part_tree.get ~disk_index ~part_index disk_part_tree)
            )
          else (disk_part_tree, None)
        in
        let disk_part_tree, boot_part_path =
          let disk_index, part_index =
            pick_choice_grouped
              ~first_header:"Select disk containing the boot partition"
              ~second_header:"Select boot partition" disk_part_tree
          in
          ( Disk_part_tree.remove_part_by_index ~disk_index ~part_index
              disk_part_tree
          , Disk_part_tree.get ~disk_index ~part_index disk_part_tree )
        in
        let sys_part_path =
          let disk_index, part_index =
            pick_choice_grouped
              ~first_header:"Select disk containing the system partition"
              ~second_header:"Select system partition" disk_part_tree
          in
          Disk_part_tree.get ~disk_index ~part_index disk_part_tree
        in
        let esp_part = Option.map make_esp_part esp_part_path in
        let boot_part = make_boot_part encrypt boot_part_path in
        let sys_part = make_sys_part encrypt sys_part_path in
        let disk_layout = make_layout ~esp_part ~boot_part ~sys_part in
        {config with disk_layout = Some disk_layout});
  reg ~name:"Formatting disk" (fun config ->
      let disk_layout = Option.get config.disk_layout in
      Disk_layout.format disk_layout;
      config);
  reg ~name:"Mounting disk" (fun config ->
      let is_efi_mode = Option.get config.is_efi_mode in
      let disk_layout = Option.get config.disk_layout in
      Disk_layout.mount_sys_part disk_layout;
      Unix.mkdir Config.boot_mount_point 0o744;
      Disk_layout.mount_boot_part disk_layout;
      if is_efi_mode then (
        Unix.mkdir Config.esp_mount_point 0o744;
        Disk_layout.mount_esp_part disk_layout );
      config);
  reg ~name:"Installing base system (base base-devel)" (fun config ->
      exec_no_capture
        (Printf.sprintf "pacstrap %s base base-devel" Config.sys_mount_point);
      config);
  reg ~name:"Generating fstab" (fun config ->
      exec
        (Printf.sprintf "genfstab -U %s >> %s/etc/fstab" Config.sys_mount_point
           Config.sys_mount_point);
      config);
  reg ~name:"Installing keyfile for /" (fun config ->
      let encrypt = Option.get config.encrypt in
      let disk_layout = Option.get config.disk_layout in
      if encrypt then (
        let sys_part_luks =
          match disk_layout.sys_part.upper with
          | Plain_FS _ ->
            failwith "Expected LUKS"
          | Luks luks ->
            luks
        in
        let keyfile_path =
          Printf.sprintf "%s/root/%s" Config.sys_mount_point
            Config.sys_part_keyfile_name
        in
        let oc = open_out_bin keyfile_path in
        Fun.protect
          ~finally:(fun () -> close_out oc)
          (fun () -> output_string oc sys_part_luks.primary_key);
        Unix.chmod keyfile_path 0o000;
        exec
          (Printf.sprintf "chmod 600 %s/initramfs-linux*"
             Config.boot_mount_point) );
      config);
  reg ~name:"Installing keyfile for unlocking /boot after boot" (fun config ->
      let encrypt = Option.get config.encrypt in
      let disk_layout = Option.get config.disk_layout in
      if encrypt then (
        let boot_part_luks =
          match disk_layout.boot_part.upper with
          | Plain_FS _ ->
            failwith "Expected LUKS"
          | Luks luks ->
            luks
        in
        let boot_secondary_key = Option.get boot_part_luks.secondary_key in
        let keyfile_path =
          Printf.sprintf "%s/root/%s" Config.sys_mount_point
            Config.boot_part_keyfile_name
        in
        let oc = open_out_bin keyfile_path in
        Fun.protect
          ~finally:(fun () -> close_out oc)
          (fun () -> output_string oc boot_secondary_key);
        () );
      config);
  reg ~name:"Setting up crypttab for unlocking and mounting /boot after boot"
    (fun config ->
       let encrypt = Option.get config.encrypt in
       let disk_layout = Option.get config.disk_layout in
       ( if encrypt then
           let boot_part_path = disk_layout.boot_part.lower.path in
           let boot_part_uuid = Disk_utils.uuid_of_dev boot_part_path in
           let keyfile_path =
             Printf.sprintf "/root/%s" Config.boot_part_keyfile_name
           in
           (* let boot_part_luks = match disk_layout.boot_part.upper with
            *   | Plain_FS _ -> failwith "Expected LUKS"
            *   | Luks luks -> luks
            * in
            * let boot_part_iter_time_ms = boot_part_luks.enc_params.iter_time_ms *)
           let line =
             Printf.sprintf "%s UUID=%s %s %s\n" Config.boot_mapper_name
               boot_part_uuid keyfile_path
               (String.concat ","
                  [Printf.sprintf "x-systemd.device-timeout=%ds" 90])
           in
           let crypttab_oc =
             open_out_gen [Open_append; Open_text] 0o600
               (Printf.sprintf "%s/etc/crypttab" Config.sys_mount_point)
           in
           Fun.protect
             ~finally:(fun () -> close_out crypttab_oc)
             (fun () -> output_string crypttab_oc line) );
       config);
  reg ~name:"Adjusting mkinitcpio.conf" (fun config ->
      let encrypt = Option.get config.encrypt in
      if encrypt then (
        let file =
          Printf.sprintf "%s/etc/mkinitcpio.conf" Config.sys_mount_point
        in
        let fill_in_FILES =
          let re = "^FILES" |> Re.Posix.re |> Re.compile in
          fun s ->
            match Re.matches re s with
            | [] ->
              [s]
            | _ ->
              [Printf.sprintf "FILES=(/root/%s)" Config.sys_part_keyfile_name]
        in
        let fill_in_HOOKS =
          let re = "^HOOKS" |> Re.Posix.re |> Re.compile in
          fun s ->
            match Re.matches re s with
            | [] ->
              [s]
            | _ ->
              [ "HOOKS=(base udev autodetect keyboard keymap consolefont \
                 modconf block encrypt lvm2 filesystems fsck)" ]
        in
        File.filter_map_lines ~file fill_in_FILES;
        File.filter_map_lines ~file fill_in_HOOKS );
      config);
  reg ~name:"Recreating images" (fun config ->
      Arch_chroot.exec "mkinitcpio -p linux";
      config);
  reg ~name:"Setting up hostname" (fun config ->
      let oc =
        open_out (Printf.sprintf "%s/etc/hostname" Config.sys_mount_point)
      in
      Fun.protect
        ~finally:(fun () -> close_out oc)
        (fun () -> output_string oc (Option.get config.hostname));
      config);
  reg ~name:"Setting up locale" (fun config ->
      let en_us = "en_US.UTF-8 UTF-8" in
      let en_dk = "en_DK.UTF-8 UTF-8" in
      let uncommet_locales =
        let re_en_us =
          Printf.sprintf "^#%s" en_us |> Re.Posix.re |> Re.compile
        in
        let re_en_dk =
          Printf.sprintf "^#%s" en_dk |> Re.Posix.re |> Re.compile
        in
        fun s ->
          match Re.matches re_en_us s with
          | [] -> (
              match Re.matches re_en_dk s with [] -> [en_dk] | _ -> [s] )
          | _ ->
            [en_us]
      in
      File.filter_map_lines
        ~file:(Printf.sprintf "%s/etc/locale.gen" Config.sys_mount_point)
        uncommet_locales;
      let oc =
        open_out_gen [Open_text; Open_append] 0o600
          (Printf.sprintf "%s/etc/locale.conf" Config.sys_mount_point)
      in
      Fun.protect
        ~finally:(fun () -> close_out oc)
        (fun () ->
           output_string oc (Printf.sprintf "LANG=%s\n" en_us);
           output_string oc (Printf.sprintf "LC_ALL=%s\n" en_us);
           output_string oc (Printf.sprintf "LC_TIME=%s\n" en_dk));
      Arch_chroot.exec "locale-gen";
      config);
  reg ~name:"Updating package database" (fun config ->
      Arch_chroot.pacman "-Sy"; config);
  reg ~name:"Installing wifi-menu" (fun config ->
      Arch_chroot.install ["dialog"; "wpa_supplicant"];
      config);
  reg ~name:"Installing bootloader packages" (fun config ->
      Arch_chroot.install ["grub"];
      if Option.get config.is_efi_mode then
        Arch_chroot.install ["efibootmgr"; "efitools"];
      config);
  reg ~name:"Updating grub config: GRUB_ENABLE_CRYPTODISK" (fun config ->
      let encrypt = Option.get config.encrypt in
      ( if encrypt then
          let default_grub_path =
            Printf.sprintf "%s/etc/default/grub" Config.sys_mount_point
          in
          let grub_enable_cryptodisk = "GRUB_ENABLE_CRYPTODISK" in
          let enable_grub_enable_cryptodisk =
            let re_uncommented =
              Printf.sprintf "^%s=" grub_enable_cryptodisk
              |> Re.Posix.re |> Re.compile
            in
            let re_commented =
              Printf.sprintf "^#%s=" grub_enable_cryptodisk
              |> Re.Posix.re |> Re.compile
            in
            fun match_count s ->
              match (Re.matches re_uncommented s, Re.matches re_commented s) with
              | [], [] ->
                (match_count, [s])
              | _, _ ->
                (succ match_count, [grub_enable_cryptodisk ^ "=y"])
          in
          let modification_count =
            File.filter_map_fold_lines ~file:default_grub_path 0
              enable_grub_enable_cryptodisk
          in
          if modification_count = 0 then
            let oc =
              open_out_gen [Open_text; Open_append] 0o600 default_grub_path
            in
            Fun.protect
              ~finally:(fun () -> close_out oc)
              (fun () -> output_string oc (grub_enable_cryptodisk ^ "=y\n")) );
      config);
  reg ~name:"Updating GRUB config: GRUB_CMDLINE_LINUX" (fun config ->
      let encrypt = Option.get config.encrypt in
      let disk_layout = Option.get config.disk_layout in
      ( if encrypt then
          let sys_part_path = disk_layout.sys_part.lower.path in
          let sys_part_uuid = Disk_utils.uuid_of_dev sys_part_path in
          let default_grub_path =
            Printf.sprintf "%s/etc/default/grub" Config.sys_mount_point
          in
          let grub_cmdline_linux = "GRUB_CMDLINE_LINUX" in
          let re =
            Printf.sprintf "^%s=" grub_cmdline_linux |> Re.Posix.re |> Re.compile
          in
          let update_grub_cmdline s =
            match Re.matches re s with
            | [] ->
              [s]
            | _ ->
              [ Printf.sprintf
                  "%s=\"cryptdevice=UUID=%s:%s cryptkey=rootfs:/root/%s \
                   root=/dev/mapper/%s\""
                  grub_cmdline_linux sys_part_uuid Config.root_mapper_name
                  Config.sys_part_keyfile_name Config.root_mapper_name ]
          in
          File.filter_map_lines ~file:default_grub_path update_grub_cmdline );
      config);
  reg ~name:"Installing GRUB to disk" (fun config ->
      let is_efi_mode = Option.get config.is_efi_mode in
      let disk_layout = Option.get config.disk_layout in
      ( if is_efi_mode then
          Arch_chroot.exec
            "grub-install --target=x86_64-efi --efi-directory=/efi \
             --bootloader-id=GRUB --recheck"
        else
          let boot_disk =
            Disk_utils.disk_of_part disk_layout.boot_part.lower.path
          in
          Arch_chroot.exec
            (Printf.sprintf
               "grub-install --target=i386-pc --boot-directory=/boot --recheck %s"
               boot_disk) );
      config);
  reg ~name:"Generating GRUB config" (fun config ->
      Arch_chroot.exec "grub-mkconfig -o /boot/grub/grub.cfg";
      config);
  reg ~name:"Setting up root password" (fun config ->
      Arch_chroot.exec_no_capture "passwd";
      config);
  reg ~name:"Setting up user" (fun config ->
      let user_name =
        ask_string_confirm
          ~is_valid:(fun s -> s <> "")
          "Please enter user name"
      in
      print_endline "Adding user";
      Arch_chroot.exec
        (Printf.sprintf "useradd -m \"%s\" -G users,wheel,rfkill" user_name);
      Printf.printf "Setting password for %s" user_name;
      Arch_chroot.exec_no_capture (Printf.sprintf "passwd %s" user_name);
      config);
  (* reg ~name:"Copying useradd helper scripts" (fun config ->
   *     let cwd = Sys.getcwd () in
   *     let dst_path = Config.sys_mount_point ^ Config.llsh_files_dir_path in
   *     FileUtil.cp [Printf.sprintf "%s/scripts/%s" cwd Config.useradd_helper1_name] dst_path;
   *     FileUtil.cp [Printf.sprintf "%s/scripts/%s" cwd Config.useradd_helper2_name] dst_path;
   *     Unix.chmod (Printf.sprintf "%s/%s" dst_path Config.useradd_helper1_name) 0o660;
   *     config
   *   );
   * reg ~name:"Setting up saltstack files" (fun config ->
   *     config
   *   ); *)
  reg ~name:"Unmounting partitions" (fun config ->
      let disk_layout = Option.get config.disk_layout in
      Disk_layout.unmount disk_layout;
      config);
  Task_book.run task_book
