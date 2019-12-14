open Proc_utils
open Misc_utils

let () =
  let config = Task_config.create () in
  let task_book = Task_book.make config in
  let reg ~name ~doc task = Task_book.register task_book ~name ~doc task in
  reg ~name:"Initialising entropy of Oali" ~doc:"" (fun _answer_store config ->
      Random.self_init ();
      config);
  reg ~name:"Increase size of cow partition"
    ~doc:"Increases the size of cow partition to 2G"
    (fun _answer_store config ->
       exec "mount -o remount,size=2G /run/archiso/cowspace";
       config);
  reg ~name:"Update time" ~doc:"Update live CD time via NTP"
    (fun _answer_store config ->
       exec "timedatectl set-ntp true";
       config);
  reg ~name:"Pick editor" ~doc:"" (fun answer_store config ->
      let editor =
        retry ~answer_store (fun () ->
            let editor =
              ask_string ~is_valid:not_empty ~answer_store
                "Please enter editor command"
            in
            try
              exec (Printf.sprintf "hash %s" editor);
              confirm_answer_is_correct_end_retry ~ret:editor
            with Exec_fail _ ->
              print_endline "Failed to find editor, please pick a different one";
              Retry)
      in
      { config with editor = Some editor });
  reg ~name:"Updating pacman database in live CD" ~doc:"Just `pacman -Sy`"
    (fun _answer_store config ->
       pacman "-Sy";
       config);
  reg ~name:"Asking if want to use reflector" ~doc:""
    (fun answer_store config ->
       let use_reflector =
         ask_yn ~answer_store
           "Do you want to use reflector to automatically sort mirrorlist by \
            rate"
         = `Yes
       in
       { config with use_reflector = Some use_reflector });
  reg ~name:"Installing reflector" ~doc:"" (fun _answer_store config ->
      if Option.get config.use_reflector then pacman "-S reflector";
      config);
  reg ~name:"Automatic configuration of mirrorlist"
    ~doc:
      {|If `reflector` was enabled, then it is used to sort the mirrorlist by download rate|}
    (fun _answer_store config ->
       if Option.get config.use_reflector then (
         let editor = Option.get config.editor in
         let countries =
           ask_string_confirm ~is_valid:not_empty
             "Please enter a comma separated list of countries you would like \
              to provide to reflector"
           |> String.split_on_char ','
         in
         let dst_path = Filename.temp_file "installer" "mirrorlist" in
         let reflector_cmd =
           [ "reflector"; "--verbose"; "--sort"; "rate"; "--save"; dst_path ]
           @ List.map (fun s -> "--country " ^ s) countries
           |> String.concat " "
         in
         Printf.printf "Computed reflector command : %s\n" reflector_cmd;
         print_newline ();
         exec_no_capture reflector_cmd;
         print_newline ();
         Printf.printf
           "%s will be used for viewing/editing the mirrorlist generated\n"
           editor;
         tell_press_enter ();
         retry (fun () ->
             exec_no_capture (Printf.sprintf "%s %s" editor dst_path);
             ask_yn_end_retry ~ret:() "Finished viewing/editing?");
         if
           ask_yn_confirm "Do you want to copy this mirrorlist over to live CD?"
           = `Yes
         then FileUtil.mv dst_path Config.livecd_mirrorlist_path );
       config);
  reg ~name:"Manual configuration of mirrorlist"
    ~doc:"Opens mirrorlist using the specified text editor"
    (fun _answer_store config ->
       let editor = Option.get config.editor in
       Printf.printf "%s will be used for editing mirrorlist\n" editor;
       tell_press_enter ();
       retry (fun () ->
           exec_no_capture
             (Printf.sprintf "%s %s" editor Config.livecd_mirrorlist_path);
           ask_yn_end_retry ~ret:() "Finished editing?");
       config);
  reg ~name:"Installing git" ~doc:"Installs git onto live CD"
    (fun _answer_store config ->
       install [ "git" ];
       config);
  reg ~name:"Asking for hostname" ~doc:"" (fun answer_store config ->
      let hostname =
        ask_string_confirm ~is_valid:not_empty ~answer_store "Hostname"
      in
      { config with hostname = Some hostname });
  reg ~name:"Asking if install hardened kernel"
    ~doc:"Installs `linux-hardened` later if answered yes"
    (fun answer_store config ->
       let add_hardened =
         ask_yn_confirm ~answer_store "Do you want to install hardened kernel?"
         = `Yes
       in
       let hardened_as_default =
         add_hardened
         && ask_yn_confirm ~answer_store
           "Do you want to set the GRUB default boot entry to the hardened \
            kernel?"
            = `Yes
       in
       {
         config with
         add_hardened = Some add_hardened;
         hardened_as_default = Some hardened_as_default;
       });
  reg ~name:"Pick whether to enable LVM"
    ~doc:
      {|If enabled, creates a single volume group over the system partition,
and 3 logical volumes for `/`, `/var`, and `/home`

If encryption is enabled as well, then the volume group is set up inside the encrypted partition
|}
    (fun answer_store config ->
       print_endline
         "If enabled, a single physical volume and a single volume group will \
          be created";
       print_endline
         "/, /var, and /home are then allocated as logical volumes in the \
          volume group";
       print_newline ();
       let use_lvm =
         ask_yn_confirm ~answer_store
           "Enable LVM for system partitions (does not include /boot, /esp)?"
         = `Yes
       in
       { config with use_lvm = Some use_lvm });
  reg ~name:"Pick whether to encrypt BOOT partition"
    ~doc:
      {|If enabled, encrypts the partition using LUKS v1
(GRUB does not support v2 yet|}
    (fun answer_store config ->
       let encrypt =
         ask_yn_confirm ~answer_store
           "Enable encryption for BOOT (/boot) partition?"
         = `Yes
       in
       { config with encrypt_boot = Some encrypt });
  let luks_doc = {|User can adjust the iteration time and key size here|} in
  reg ~name:"Adjusting cryptsetup parameters for boot partition" ~doc:luks_doc
    (fun answer_store config ->
       if Option.get config.encrypt_boot then
         let iter_time_ms, key_size_bits =
           retry ~answer_store (fun () ->
               let iter_time_ms =
                 if
                   ask_yn ~answer_store
                     "Do you want to adjust iteration time of boot partition?"
                   = `Yes
                 then
                   Some
                     (ask_uint ~answer_store "Please enter iteration time in ms")
                 else None
               in
               let key_size_bits =
                 if
                   ask_yn ~answer_store
                     "Do you want to adjust key size of boot partition?"
                   = `Yes
                 then
                   Some (ask_uint ~answer_store "Please enter key size in bits")
                 else None
               in
               ask_yn_end_retry
                 ~ret:(iter_time_ms, key_size_bits)
                 "Are the above answers correct?")
         in
         {
           config with
           boot_part_enc_params = Some { iter_time_ms; key_size_bits };
         }
       else config);
  reg
    ~name:"Pick whether to encrypt ROOT partition (or physical volume for LVM)"
    ~doc:
      {|If enabled, encrypts the system volume using LUKS v2

Oali will double check with the user if BOOT partition was configured to
to be encrypted, but picking no for ROOT partition here

User is allowed to continue said setup if they wishes to however
|}
    (fun answer_store config ->
       let use_lvm = Option.get config.use_lvm in
       let encrypt_boot = Option.get config.encrypt_boot in
       let encrypt =
         retry ~answer_store (fun () ->
             let encrypt_sys =
               ask_yn ~answer_store
                 ( if use_lvm then "Enable encryption for system physical volume?"
                   else "Enable encryption for ROOT (/) partition?" )
               = `Yes
             in
             if encrypt_boot && not encrypt_sys then
               print_boxed_msg
                 "WARNING : boot was configured to be encrypted, but you \
                  selected to not encrypt root";
             confirm_answer_is_correct_end_retry ~ret:encrypt_sys)
       in
       { config with encrypt_sys = Some encrypt });
  reg ~name:"Adjusting cryptsetup parameters for root partition" ~doc:luks_doc
    (fun answer_store config ->
       if Option.get config.encrypt_sys then
         let iter_time_ms, key_size_bits =
           retry ~answer_store (fun () ->
               let iter_time_ms =
                 if
                   ask_yn ~answer_store
                     "Do you want to adjust iteration time of root partition?"
                   = `Yes
                 then
                   Some
                     (ask_uint ~answer_store "Please enter iteration time in ms")
                 else None
               in
               let key_size_bits =
                 if
                   ask_yn ~answer_store
                     "Do you want to adjust key size of root partition?"
                   = `Yes
                 then
                   Some (ask_uint ~answer_store "Please enter key size in bits")
                 else None
               in
               ask_yn_end_retry
                 ~ret:(iter_time_ms, key_size_bits)
                 "Are the above answers correct?")
         in
         {
           config with
           sys_part_enc_params = Some { iter_time_ms; key_size_bits };
         }
       else config);
  reg ~name:"Pick disk layout choice"
    ~doc:
      {|User picks from one of the three disk layouts

- Single system disk

- Manual picking

- Single system partition + USB key
|}
    (fun _answer_store config ->
       let open Disk_layout in
       let choices =
         [
           ("single disk", Single_disk);
           ( "system partition + boot partition + maybe EFI partition",
             Sys_part_plus_boot_plus_maybe_EFI );
           ( "system partition + boot stuff on external USB drive",
             Sys_part_plus_usb_drive );
         ]
       in
       let choice = pick_choice_kv choices in
       { config with disk_layout_choice = Some choice });
  reg ~name:"Checking if in EFI mode" ~doc:"" (fun _answer_store config ->
      let is_efi_mode = Sys.file_exists "/sys/firmware/efi" in
      { config with is_efi_mode = Some is_efi_mode });
  reg ~name:"Configure disk setup parameters"
    ~doc:
      {|Select disk and/or partitions based on previously picked disk layout,
then partitions the disk(s) based on the choices using `parted`

Partition sizes are calculated on Oali's side and passed to `parted`
as percentages to ensure the partition boundaries are aligned optimially
|}
    (fun _answer_store config ->
       let open Disk_layout in
       let use_lvm = Option.get config.use_lvm in
       let boot_encrypt = Option.get config.encrypt_boot in
       let sys_encrypt = Option.get config.encrypt_sys in
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
             "`Not enough disks found, please make sure you have connected at \
              least one disk";
         let disk =
           retry (fun () ->
               let disk = pick_choice_value ~header:"Disks" disks in
               ask_yn_end_retry ~ret:disk
                 (Printf.sprintf
                    "Partition table of %s will be wiped if you proceed, is \
                     it the right disk?"
                    disk))
         in
         (* reset partition table *)
         Printf.printf "Wiping partition table of %s\n" disk;
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
         let disk_size_MiB = Disk_utils.disk_size_MiB disk in
         let boot_part_frac =
           calc_frac ~max_frac:Config.boot_part_max_frac
             ~value:Config.boot_part_size_MiB ~total:disk_size_MiB
         in
         if is_efi_mode then (
           let esp_part_frac =
             calc_frac ~max_frac:Config.esp_part_max_frac
               ~value:Config.esp_part_size_MiB ~total:disk_size_MiB
           in
           let esp_part_end_MiB = disk_size_MiB *. esp_part_frac in
           let boot_part_beg_MiB = esp_part_end_MiB in
           let boot_part_end_MiB =
             boot_part_beg_MiB +. (disk_size_MiB *. boot_part_frac)
           in
           let esp_part_end_MB =
             esp_part_end_MiB |> Unit_convert.from_MiB_to_MB |> int_of_float
           in
           let boot_part_beg_MB =
             boot_part_beg_MiB |> Unit_convert.from_MiB_to_MB |> int_of_float
           in
           let boot_part_end_MB =
             boot_part_end_MiB |> Unit_convert.from_MiB_to_MB |> int_of_float
           in
           exec
             (Printf.sprintf "parted -a optimal %s mkpart primary 0%% %dMB"
                disk esp_part_end_MB);
           exec
             (Printf.sprintf "parted -a optimal %s mkpart primary %dMB %dMB"
                disk boot_part_beg_MB boot_part_end_MB);
           exec
             (Printf.sprintf "parted -a optimal %s mkpart primary %dMB %d%%"
                disk boot_part_end_MB
                (frac_to_perc Config.total_disk_usage_frac));
           exec (Printf.sprintf "parted %s set 1 boot on" disk);
           let parts = Disk_utils.parts_of_disk disk in
           let esp_part_path = List.nth parts 0 |> Option.some in
           let boot_part_path = List.nth parts 1 in
           let sys_part_path = List.nth parts 2 in
           let disk_layout =
             make_layout ~esp_part_path ~boot_part_path
               ~boot_part_enc_params:config.boot_part_enc_params ~boot_encrypt
               ~sys_part_path ~sys_part_enc_params:config.sys_part_enc_params
               ~sys_encrypt ~use_lvm
           in
           { config with disk_layout = Some disk_layout } )
         else
           let boot_part_end_MiB = disk_size_MiB *. boot_part_frac in
           let boot_part_end_MB =
             boot_part_end_MiB |> Unit_convert.from_MiB_to_MB |> int_of_float
           in
           exec
             (Printf.sprintf "parted -a optimal %s mkpart primary 0%% %dMB"
                disk boot_part_end_MB);
           exec
             (Printf.sprintf "parted -a optimal %s mkpart primary %dMB %d%%"
                disk boot_part_end_MB
                (frac_to_perc Config.total_disk_usage_frac));
           exec (Printf.sprintf "parted %s set 1 boot on" disk);
           let parts = Disk_utils.parts_of_disk disk in
           let boot_part_path = List.nth parts 0 in
           let sys_part_path = List.nth parts 1 in
           let disk_layout =
             make_layout ~esp_part_path:None ~boot_part_path
               ~boot_part_enc_params:config.boot_part_enc_params ~boot_encrypt
               ~sys_part_path ~sys_part_enc_params:config.sys_part_enc_params
               ~sys_encrypt ~use_lvm
           in
           { config with disk_layout = Some disk_layout }
       | Sys_part_plus_boot_plus_maybe_EFI ->
         let parts = Disk_utils.list_parts () in
         if
           (is_efi_mode && List.length parts < 3)
           || ((not is_efi_mode) && List.length parts < 2)
         then
           failwith
             "`Not enough partitions found, please make sure partitioning was \
              done correctly";
         let disk_part_tree = Disk_part_tree.of_parts parts in
         let disk_part_tree, esp_part_path =
           if is_efi_mode then
             let disk_index, part_index =
               pick_choice_grouped_num
                 ~first_header:"Select disk containing the EFI partition"
                 ~second_header:"Select EFI partition" disk_part_tree
             in
             ( Disk_part_tree.remove_part_by_index ~disk_index ~part_index
                 disk_part_tree,
               Some (Disk_part_tree.get ~disk_index ~part_index disk_part_tree)
             )
           else (disk_part_tree, None)
         in
         let disk_part_tree, boot_part_path =
           let disk_index, part_index =
             pick_choice_grouped_num
               ~first_header:"Select disk containing the boot partition"
               ~second_header:"Select boot partition" disk_part_tree
           in
           ( Disk_part_tree.remove_part_by_index ~disk_index ~part_index
               disk_part_tree,
             Disk_part_tree.get ~disk_index ~part_index disk_part_tree )
         in
         let sys_part_path =
           let disk_index, part_index =
             pick_choice_grouped_num
               ~first_header:"Select disk containing the system partition"
               ~second_header:"Select system partition" disk_part_tree
           in
           Disk_part_tree.get ~disk_index ~part_index disk_part_tree
         in
         (let boot_disk = Disk_utils.disk_of_part boot_part_path in
          let boot_part_num =
            String_utils.get_tail_num boot_part_path |> Option.get
          in
          exec
            (Printf.sprintf "parted %s set %d boot on" boot_disk boot_part_num));
         let disk_layout =
           make_layout ~esp_part_path ~boot_part_path
             ~boot_part_enc_params:config.boot_part_enc_params ~boot_encrypt
             ~sys_part_path ~sys_part_enc_params:config.sys_part_enc_params
             ~sys_encrypt ~use_lvm
         in
         { config with disk_layout = Some disk_layout }
       | Sys_part_plus_usb_drive ->
         let parts = Disk_utils.list_parts () in
         if List.length parts < 1 then
           failwith
             "`Not enough partitions found, please make sure partitioning was \
              done correctly";
         let disk_part_tree = Disk_part_tree.of_parts parts in
         let sys_part_path =
           let disk_index, part_index =
             pick_choice_grouped_num
               ~first_header:"Select disk containing the system partition"
               ~second_header:"Select system partition" disk_part_tree
           in
           Disk_part_tree.get ~disk_index ~part_index disk_part_tree
         in
         let disks =
           Disk_utils.list_disks ()
           |> List.filter (fun s -> s <> Disk_utils.disk_of_part sys_part_path)
         in
         if List.length disks < 1 then
           failwith
             "`Not enough disks left, please make sure you have attached the \
              USB drive";
         let usb_key =
           retry (fun () ->
               let disk = pick_choice_value ~header:"Select USB drive" disks in
               ask_yn_end_retry ~ret:disk
                 (Printf.sprintf
                    "Partition table of %s will be wiped if you proceed, is \
                     it the right disk?"
                    disk))
         in
         (* reset partition table *)
         Printf.printf "Wiping partition table of %s\n" usb_key;
         exec (Printf.sprintf "dd if=/dev/zero of=%s bs=512 count=2" usb_key);
         (* create partition table *)
         if is_efi_mode then (
           print_endline "Creating GPT partition table";
           exec (Printf.sprintf "parted %s mklabel gpt" usb_key) )
         else (
           print_endline "Creating MBR partition table";
           exec (Printf.sprintf "parted %s mklabel msdos" usb_key) );
         (* partitioning USB key *)
         print_endline "Partitioning";
         let usb_key_size_MiB = Disk_utils.disk_size_MiB usb_key in
         let boot_part_frac =
           calc_frac ~max_frac:Config.boot_part_max_frac
             ~value:Config.boot_part_size_MiB ~total:usb_key_size_MiB
         in
         if is_efi_mode then (
           let esp_part_perc =
             calc_frac ~max_frac:Config.esp_part_max_frac
               ~value:Config.esp_part_size_MiB ~total:usb_key_size_MiB
           in
           let esp_part_end_MiB = usb_key_size_MiB *. esp_part_perc in
           let boot_part_beg_MiB = esp_part_end_MiB in
           let boot_part_end_MiB =
             boot_part_beg_MiB +. (usb_key_size_MiB *. boot_part_frac)
           in
           let esp_part_end_MB =
             esp_part_end_MiB |> Unit_convert.from_MiB_to_MB |> int_of_float
           in
           let boot_part_beg_MB =
             boot_part_beg_MiB |> Unit_convert.from_MiB_to_MB |> int_of_float
           in
           let boot_part_end_MB =
             boot_part_end_MiB |> Unit_convert.from_MiB_to_MB |> int_of_float
           in
           exec
             (Printf.sprintf "parted -a optimal %s mkpart primary 0%% %dMB"
                usb_key esp_part_end_MB);
           exec
             (Printf.sprintf "parted -a optimal %s mkpart primary %dMB %dMB"
                usb_key boot_part_beg_MB boot_part_end_MB);
           exec (Printf.sprintf "parted %s set 1 boot on" usb_key);
           let parts = Disk_utils.parts_of_disk usb_key in
           let esp_part_path = List.nth parts 0 |> Option.some in
           let boot_part_path = List.nth parts 1 in
           let disk_layout =
             make_layout ~esp_part_path ~boot_part_path
               ~boot_part_enc_params:config.boot_part_enc_params ~boot_encrypt
               ~sys_part_path ~sys_part_enc_params:config.sys_part_enc_params
               ~sys_encrypt ~use_lvm
           in
           { config with disk_layout = Some disk_layout } )
         else
           let boot_part_end_MiB = usb_key_size_MiB *. boot_part_frac in
           let boot_part_end_MB =
             boot_part_end_MiB |> Unit_convert.from_MiB_to_MB |> int_of_float
           in
           exec
             (Printf.sprintf "parted -a optimal %s mkpart primary 0%% %dMB"
                usb_key boot_part_end_MB);
           exec (Printf.sprintf "parted %s set 1 boot on" usb_key);
           let parts = Disk_utils.parts_of_disk usb_key in
           let boot_part_path = List.nth parts 0 in
           let disk_layout =
             make_layout ~esp_part_path:None ~boot_part_path
               ~boot_part_enc_params:config.boot_part_enc_params ~boot_encrypt
               ~sys_part_path ~sys_part_enc_params:config.sys_part_enc_params
               ~sys_encrypt ~use_lvm
           in
           { config with disk_layout = Some disk_layout });
  reg ~name:"Setting up disk"
    ~doc:
      {|LUKS, LVM, file system formatting are set up at this stage when applicable|}
    (fun _answer_store config ->
       let disk_layout = Option.get config.disk_layout in
       ( try Disk_layout.set_up disk_layout
         with e ->
           Disk_layout.reset disk_layout;
           raise e );
       config);
  reg ~name:"Mounting disk"
    ~doc:{|Mount all partitions with root being at `/mnt`|}
    (fun _answer_store config ->
       (* let is_efi_mode = Option.get config.is_efi_mode in *)
       let disk_layout = Option.get config.disk_layout in
       Disk_layout.mount disk_layout;
       (* Disk_layout.mount_root_var_home disk_layout;
        * Unix.mkdir Config.boot_mount_point 0o744;
        * Disk_layout.mount_boot disk_layout;
        * if is_efi_mode then (
        *   Unix.mkdir Config.esp_mount_point 0o744;
        *   Disk_layout.mount_esp disk_layout ); *)
       config);
  reg ~name:"Installing base system (base linux base-devel)" ~doc:""
    (fun _answer_store config ->
       exec_no_capture
         (Printf.sprintf "pacstrap %s base linux base-devel"
            Config.root_mount_point);
       config);
  reg ~name:"Generating fstab"
    ~doc:
      {|Invokes `genfstab`, and comments out entry for `/boot`
if using the USB key disk layout|}
    (fun _answer_store config ->
       let fstab_path =
         concat_file_names [ Config.root_mount_point; "etc"; "fstab" ]
       in
       exec
         (Printf.sprintf "genfstab -U %s >> %s" Config.root_mount_point
            fstab_path);
       if
         Option.get config.disk_layout_choice
         = Disk_layout.Sys_part_plus_usb_drive
       then
         File.filter_map_lines ~file:fstab_path (fun s ->
             match
               ( Core_kernel.String.substr_index s ~pattern:Config.boot_dir,
                 Core_kernel.String.substr_index s ~pattern:Config.efi_dir )
             with
             | None, None -> [ s ]
             | _, _ -> [ "# " ^ s ]);
       config);
  reg ~name:"Installing keyfile for /"
    ~doc:{|Sets up keyfile to be embedded into the initramfs|}
    (fun _answer_store config ->
       if Option.get config.encrypt_sys then (
         let disk_layout = Option.get config.disk_layout in
         let root = Disk_layout.get_root disk_layout in
         match root.l1 with
         | Clear _ -> failwith "Expected LUKS"
         | Luks { info; _ } ->
           let keyfile_path =
             concat_file_names
               [
                 Config.root_mount_point; "root"; Config.sys_part_keyfile_name;
               ]
           in
           let oc = open_out_bin keyfile_path in
           Fun.protect
             ~finally:(fun () -> close_out oc)
             (fun () -> output_string oc info.primary_key);
           Unix.chmod keyfile_path 0o000 )
       else print_endline "Skipped";
       config);
  reg ~name:"Installing keyfile for unlocking /boot after boot"
    ~doc:
      {|Installs secondary keyfile for /boot

The keyfile is referenced in crypttab later|}
    (fun _answer_store config ->
       if
         Option.get config.disk_layout_choice
         <> Disk_layout.Sys_part_plus_usb_drive
       then
         if Option.get config.encrypt_boot then (
           let disk_layout = Option.get config.disk_layout in
           let boot = Disk_layout.get_boot disk_layout in
           match boot.l1 with
           | Clear _ -> failwith "Expected LUKS"
           | Luks { info; _ } ->
             let boot_secondary_key = Option.get info.secondary_key in
             let keyfile_path =
               concat_file_names
                 [
                   Config.root_mount_point;
                   "root";
                   Config.boot_part_keyfile_name;
                 ]
             in
             let oc = open_out_bin keyfile_path in
             Fun.protect
               ~finally:(fun () -> close_out oc)
               (fun () -> output_string oc boot_secondary_key);
             () )
         else print_endline "Skipped";
       config);
  reg ~name:"Setting up crypttab for unlocking and mounting /boot after boot"
    ~doc:
      {|Append a line to crypttab file using the secondary keyfile for /boot,
allowing decryption of boot partition after booting

The line is then commented if disk layout uses USB key|}
    (fun _answer_store config ->
       ( if Option.get config.encrypt_boot then
           let disk_layout = Option.get config.disk_layout in
           let boot_part_path =
             let boot = Disk_layout.get_boot disk_layout in
             match boot.l1 with
             | Clear _ -> failwith "Expected LUKS"
             | Luks { path; _ } -> path
           in
           let boot_part_uuid = Disk_utils.uuid_of_dev boot_part_path in
           let keyfile_path =
             concat_file_names [ "/root"; Config.boot_part_keyfile_name ]
           in
           let comment_str =
             if
               Option.get config.disk_layout_choice
               = Disk_layout.Sys_part_plus_usb_drive
             then "# "
             else ""
           in
           let line =
             Printf.sprintf "%s%s UUID=%s %s %s\n" Config.boot_mapper_name
               comment_str boot_part_uuid keyfile_path
               (String.concat ","
                  [ Printf.sprintf "x-systemd.device-timeout=%ds" 90 ])
           in
           let crypttab_oc =
             open_out_gen [ Open_append; Open_text ] 0o600
               (concat_file_names [ Config.root_mount_point; "etc"; "crypttab" ])
           in
           Fun.protect
             ~finally:(fun () -> close_out crypttab_oc)
             (fun () ->
                output_string crypttab_oc "\n";
                output_string crypttab_oc line;
                output_string crypttab_oc "\n") );
       config);
  reg ~name:"Adjusting mkinitcpio.conf"
    ~doc:
      {|Adds appropriate mkinitcpio hooks based on LUKS and LVM choices specified|}
    (fun _answer_store config ->
       let encrypt_sys = Option.get config.encrypt_sys in
       let use_lvm = Option.get config.use_lvm in
       let file =
         concat_file_names [ Config.root_mount_point; "etc"; "mkinitcpio.conf" ]
       in
       let fill_in_FILES =
         let re = "^FILES" |> Re.Posix.re |> Re.compile in
         fun s ->
           match Re.matches re s with
           | [] -> [ s ]
           | _ ->
             if encrypt_sys then
               [
                 Printf.sprintf "FILES=(%s)"
                   (concat_file_names
                      [ "/root"; Config.sys_part_keyfile_name ]);
               ]
             else [ s ]
       in
       let fill_in_HOOKS =
         let re = "^HOOKS" |> Re.Posix.re |> Re.compile in
         fun s ->
           match Re.matches re s with
           | [] -> [ s ]
           | _ ->
             [
               Printf.sprintf "HOOKS=(%s)"
                 (String.concat " "
                    (Config.gen_mkinitcpio_hooks ~encrypt_sys ~use_lvm));
             ]
       in
       File.filter_map_lines ~file fill_in_FILES;
       File.filter_map_lines ~file fill_in_HOOKS;
       config);
  reg ~name:"Installing lvm2 onto system on disk"
    ~doc:{|Install `lvm2` package into system on disk if LVM is enabled|}
    (fun _answer_store config ->
       if Option.get config.use_lvm then Arch_chroot.install [ "lvm2" ];
       config);
  reg ~name:"Recreating images"
    ~doc:"Recreate initramfs so the new mkinitcpio hooks are installed"
    (fun _answer_store config ->
       Arch_chroot.exec "mkinitcpio -p linux";
       config);
  reg ~name:"Installing hardened kernel" ~doc:"" (fun _answer_store config ->
      if Option.get config.add_hardened then
        Arch_chroot.install [ "linux-hardened"; "linux-hardened-headers" ];
      config);
  reg ~name:"Updating initramfs permissions" ~doc:""
    (fun _answer_store config ->
       exec
         (Printf.sprintf "chmod 600 %s/initramfs-linux*" Config.boot_mount_point);
       config);
  reg ~name:"Setting up hostname" ~doc:"" (fun _answer_store config ->
      let oc =
        open_out
          (concat_file_names [ Config.root_mount_point; "etc"; "hostname" ])
      in
      Fun.protect
        ~finally:(fun () -> close_out oc)
        (fun () -> output_string oc (Option.get config.hostname));
      config);
  reg ~name:"Setting up locale" ~doc:"" (fun _answer_store config ->
      (let en_us_locale_gen = "en_US.UTF-8 UTF-8" in
       let en_dk_locale_gen = "en_DK.UTF-8 UTF-8" in
       let uncommet_locales =
         let re_en_us =
           Printf.sprintf "^#%s" en_us_locale_gen |> Re.Posix.re |> Re.compile
         in
         let re_en_dk =
           Printf.sprintf "^#%s" en_dk_locale_gen |> Re.Posix.re |> Re.compile
         in
         fun s ->
           match Re.matches re_en_us s with
           | [] -> (
               match Re.matches re_en_dk s with
               | [] -> [ s ]
               | _ -> [ en_dk_locale_gen ] )
           | _ -> [ en_us_locale_gen ]
       in
       File.filter_map_lines
         ~file:
           (concat_file_names [ Config.root_mount_point; "etc"; "locale.gen" ])
         uncommet_locales);
      (let en_us_locale_conf = "en_US.UTF-8" in
       let en_dk_locale_conf = "en_DK.UTF-8" in
       let oc =
         open_out
           (concat_file_names [ Config.root_mount_point; "etc"; "locale.conf" ])
       in
       Fun.protect
         ~finally:(fun () -> close_out oc)
         (fun () ->
            output_string oc (Printf.sprintf "LANG=%s\n" en_us_locale_conf);
            output_string oc (Printf.sprintf "LC_ALL=%s\n" en_us_locale_conf);
            output_string oc (Printf.sprintf "LC_TIME=%s\n" en_dk_locale_conf));
       Arch_chroot.exec "locale-gen");
      config);
  (* reg ~name:"Updating package database" ~doc:"" (fun _answer_store config ->
   *     Arch_chroot.pacman "-Sy";
   *     config); *)
  reg ~name:"Installing wifi-menu" ~doc:"" (fun _answer_store config ->
      Arch_chroot.install [ "dialog"; "wpa_supplicant" ];
      config);
  reg ~name:"Installing dhcpcd" ~doc:"" (fun _answer_store config ->
      Arch_chroot.install [ "dhcpcd" ];
      config);
  reg ~name:"Installing bootloader packages" ~doc:{|Install GRUB bootloader|}
    (fun _answer_store config ->
       Arch_chroot.install [ "grub" ];
       if Option.get config.is_efi_mode then
         Arch_chroot.install [ "efibootmgr"; "efitools" ];
       config);
  reg ~name:"Updating GRUB config: GRUB_ENABLE_CRYPTODISK" ~doc:""
    (fun _answer_store config ->
       let encrypt = Option.get config.encrypt_boot in
       ( if encrypt then
           let default_grub_path =
             concat_file_names
               [ Config.root_mount_point; "etc"; "default"; "grub" ]
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
               | [], [] -> (match_count, [ s ])
               | _, _ -> (succ match_count, [ grub_enable_cryptodisk ^ "=y" ])
           in
           let modification_count =
             File.filter_map_fold_lines ~file:default_grub_path 0
               enable_grub_enable_cryptodisk
           in
           if modification_count = 0 then
             let oc =
               open_out_gen [ Open_text; Open_append ] 0o600 default_grub_path
             in
             Fun.protect
               ~finally:(fun () -> close_out oc)
               (fun () -> output_string oc (grub_enable_cryptodisk ^ "=y\n")) );
       config);
  reg ~name:"Updating GRUB config: GRUB_CMDLINE_LINUX"
    ~doc:
      {|If LUKS is enabled, adjusts the `GRUB_CMDLINE_LINUX` line in grub config to specify
the system partition, the associated keyfile, and root volume|}
    (fun _answer_store config ->
       let disk_layout = Option.get config.disk_layout in
       let grub_cmdline_linux = "GRUB_CMDLINE_LINUX" in
       let use_lvm = Option.get config.use_lvm in
       let re =
         Printf.sprintf "^%s=" grub_cmdline_linux |> Re.Posix.re |> Re.compile
       in
       let default_grub_path =
         concat_file_names [ Config.root_mount_point; "etc"; "default"; "grub" ]
       in
       let root = Disk_layout.get_root disk_layout in
       ( match root.l1 with
         | Clear _ -> ()
         (* | Clear { path } ->
          *   let update_grub_cmdline s =
          *     match Re.matches re s with
          *     | [] -> [ s ]
          *     | _ ->
          *       if use_lvm then
          *         [
          *           Printf.sprintf "%s=\"root=/dev/%s/%s\"" grub_cmdline_linux
          *             Config.lvm_vg_name Config.lvm_lv_root_name;
          *         ]
          *       else
          *         let sys_part_uuid = Disk_utils.uuid_of_dev path in
          *         [
          *           Printf.sprintf "%s=\"root=UUID=%s\"" grub_cmdline_linux
          *             sys_part_uuid;
          *         ]
          *   in
          *   File.filter_map_lines ~file:default_grub_path update_grub_cmdline *)
         | Luks { path; _ } ->
           let sys_part_uuid = Disk_utils.uuid_of_dev path in
           let update_grub_cmdline s =
             match Re.matches re s with
             | [] -> [ s ]
             | _ ->
               if use_lvm then
                 [
                   Printf.sprintf
                     "%s=\"cryptdevice=UUID=%s:%s cryptkey=rootfs:/root/%s \
                      root=/dev/%s/%s\""
                     grub_cmdline_linux sys_part_uuid Config.sys_mapper_name
                     Config.sys_part_keyfile_name Config.lvm_vg_name
                     Config.lvm_lv_root_name;
                 ]
               else
                 [
                   Printf.sprintf
                     "%s=\"cryptdevice=UUID=%s:%s cryptkey=rootfs:/root/%s \
                      root=/dev/mapper/%s\""
                     grub_cmdline_linux sys_part_uuid Config.sys_mapper_name
                     Config.sys_part_keyfile_name Config.sys_mapper_name;
                 ]
           in
           File.filter_map_lines ~file:default_grub_path update_grub_cmdline );
       config);
  reg ~name:"Setting hardened kernel as default boot entry" ~doc:""
    (fun _answer_store config ->
       let file =
         concat_file_names [ Config.root_mount_point; "etc"; "default"; "grub" ]
       in
       ( if Option.get config.hardened_as_default then
           let update_grub_default =
             let grub_default = "GRUB_DEFAULT" in
             let entry_str =
               "Advanced options for Arch Linux>Arch Linux, with Linux \
                linux-hardened"
             in
             let re =
               Printf.sprintf "^%s" grub_default |> Re.Posix.re |> Re.compile
             in
             fun s ->
               match Re.matches re s with
               | [] -> [ s ]
               | _ -> [ Printf.sprintf "%s=\"%s\"" grub_default entry_str ]
           in
           File.filter_map_lines ~file update_grub_default );
       config);
  reg ~name:"Installing GRUB to disk"
    ~doc:
      {|Invokes `grub-install` with parameters based on whether in BIOS or UEFI mode,
and also based on disk layout

Specifically, `--removable` flag is added if disk layout uses USB key|}
    (fun _answer_store config ->
       let is_efi_mode = Option.get config.is_efi_mode in
       let disk_layout = Option.get config.disk_layout in
       let use_usb_key =
         Option.get config.disk_layout_choice
         = Disk_layout.Sys_part_plus_usb_drive
       in
       let removable_flag = if use_usb_key then "--removable" else "" in
       ( if is_efi_mode then
           Arch_chroot.exec
             (Printf.sprintf
                "grub-install %s --target=x86_64-efi --efi-directory=%s \
                 --bootloader-id=GRUB --recheck"
                removable_flag Config.efi_dir)
         else
           let boot_path =
             let boot = Disk_layout.get_boot disk_layout in
             match boot.l1 with Clear { path } -> path | Luks { path; _ } -> path
           in
           let boot_disk = Disk_utils.disk_of_part boot_path in
           Arch_chroot.exec
             (Printf.sprintf
                "grub-install %s --target=i386-pc --boot-directory=%s --recheck %s"
                removable_flag Config.boot_dir boot_disk) );
       config);
  reg ~name:"Generating GRUB config" ~doc:{|Invokes `grub-mkconfig`|}
    (fun _answer_store config ->
       Arch_chroot.exec "grub-mkconfig -o /boot/grub/grub.cfg";
       config);
  reg ~name:"Setting up root password" ~doc:"" (fun _answer_store config ->
      Arch_chroot.exec_no_capture "passwd";
      config);
  reg ~name:"Setting user account" ~doc:"" (fun answer_store config ->
      let user_name =
        ask_string_confirm ~is_valid:not_empty ~answer_store
          "Please enter user name"
      in
      print_endline "Adding user";
      Arch_chroot.exec
        (Printf.sprintf "useradd -m \"%s\" -G users,wheel,rfkill" user_name);
      { config with user_name = Some user_name });
  reg ~name:"Setting user password" ~doc:"" (fun _answer_store config ->
      let user_name = Option.get config.user_name in
      Printf.printf "Setting password for %s" user_name;
      Arch_chroot.exec_no_capture (Printf.sprintf "passwd %s" user_name);
      config);
  reg ~name:"Creating oali files folder"
    ~doc:{|Sets up user facing notes for post-install stuff|}
    (fun _answer_store config ->
       let dst_path =
         concat_file_names
           [ Config.root_mount_point; Config.oali_files_dir_path ]
       in
       FileUtil.mkdir dst_path;
       config);
  reg ~name:"Generating USB key mounting and unmounting scripts"
    ~doc:
      {|If disk layout uses USB key, generates scripts with appropriate UUIDs
embedded for mounting and unmounting the USB key partitions|}
    (fun _answer_store config ->
       let use_usb_key =
         Option.get config.disk_layout_choice
         = Disk_layout.Sys_part_plus_usb_drive
       in
       let disk_layout = Option.get config.disk_layout in
       if use_usb_key then (
         let encrypt_boot = Option.get config.encrypt_boot in
         let is_efi_mode = Option.get config.is_efi_mode in
         let boot_part_path =
           let boot = Disk_layout.get_boot disk_layout in
           match boot.l1 with Clear { path } -> path | Luks { path; _ } -> path
         in
         let boot_part_uuid = Disk_utils.uuid_of_dev boot_part_path in
         let esp_part_path =
           Option.map
             (fun (esp : Storage_unit.instance) ->
                match esp.l1 with
                | Clear { path } -> path
                | Luks { path; _ } -> path)
             (Disk_layout.get_esp disk_layout)
         in
         let esp_part_uuid =
           Option.map (fun path -> Disk_utils.uuid_of_dev path) esp_part_path
         in
         (let dst_path =
            concat_file_names
              [
                Config.root_mount_point;
                Config.oali_files_dir_path;
                Config.usb_key_mount_script_name;
              ]
          in
          let script =
            Usb_key_mount_script_template.gen ~encrypt:encrypt_boot ~is_efi_mode
              ~esp_part_uuid ~boot_part_uuid
          in
          let oc = open_out dst_path in
          Fun.protect
            ~finally:(fun () -> close_out oc)
            (fun () -> output_string oc script));
         let dst_path =
           concat_file_names
             [
               Config.root_mount_point;
               Config.oali_files_dir_path;
               Config.usb_key_unmount_script_name;
             ]
         in
         let script =
           Usb_key_unmount_script_template.gen ~encrypt:encrypt_boot ~is_efi_mode
         in
         let oc = open_out dst_path in
         Fun.protect
           ~finally:(fun () -> close_out oc)
           (fun () -> output_string oc script) );
       config);
  reg ~name:"Generating useradd helper scripts" ~doc:""
    (fun _answer_store config ->
       (let dst_path =
          concat_file_names
            [
              Config.root_mount_point;
              Config.oali_files_dir_path;
              Config.useradd_helper_restricted_name;
            ]
        in
        let script = Useradd_helper_restricted_script_template.gen () in
        let oc = open_out dst_path in
        Fun.protect
          ~finally:(fun () -> close_out oc)
          (fun () -> output_string oc script);
        Unix.chmod dst_path 0o660);
       (let dst_path =
          concat_file_names
            [
              Config.root_mount_point;
              Config.oali_files_dir_path;
              Config.useradd_helper_as_powerful_name;
            ]
        in
        let script = Useradd_helper_as_powerful_script_template.gen () in
        let oc = open_out dst_path in
        Fun.protect
          ~finally:(fun () -> close_out oc)
          (fun () -> output_string oc script);
        Unix.chmod dst_path 0o660);
       config);
  reg ~name:"Ask if enable SSH server" ~doc:"" (fun answer_store config ->
      let enable_ssh_server =
        ask_yn_confirm ~answer_store "Do you want to enable SSH server?" = `Yes
      in
      { config with enable_ssh_server = Some enable_ssh_server });
  reg ~name:"Installing SSH server" ~doc:"" (fun _answer_store config ->
      if Option.get config.enable_ssh_server then
        Arch_chroot.install [ "openssh" ];
      config);
  reg ~name:"Generating sshd_config" ~doc:"" (fun _answer_store config ->
      if Option.get config.enable_ssh_server then (
        let script = Sshd_config_template.gen ~port:Config.sshd_port in
        let dst_path = Config.etc_sshd_config_path in
        let oc = open_out dst_path in
        Fun.protect
          ~finally:(fun () -> close_out oc)
          (fun () -> output_string oc script);
        Unix.chmod dst_path 0o600 );
      config);
  reg ~name:"Enabling SSH server" ~doc:"" (fun _answer_store config ->
      if Option.get config.enable_ssh_server then
        Arch_chroot.exec "systemctl enable sshd";
      config);
  reg ~name:"Setting up SSH key directory" ~doc:"" (fun _answer_store config ->
      if Option.get config.enable_ssh_server then (
        let user_name = Option.get config.user_name in
        let user_ssh_dir_path =
          concat_file_names
            [ Config.root_mount_point; "home"; user_name; ".ssh" ]
        in
        FileUtil.mkdir user_ssh_dir_path;
        let user_ssh_authorized_keys_path =
          concat_file_names [ user_ssh_dir_path; "authorized_keys" ]
        in
        {
          config with
          user_ssh_authorized_keys_path = Some user_ssh_authorized_keys_path;
        } )
      else config);
  reg ~name:"Transferring SSH public keys"
    ~doc:
      {|User can transfer the public key via command using `ncat` (for network transfer) and `gpg` (for symmetric encryption using a randomly generated alphanumeric passphrase)

Technically encryption of public is not necessary. The encryption
is to limit the damage of accidentally transferring private key instead
of the public key.
|}
    (fun _answer_store config ->
       ( if Option.get config.enable_ssh_server then
           let ip = Net_utils.get_internet_facing_ip () in
           retry (fun () ->
               let otp = Rand_utils.gen_rand_alphanum_string ~len:12 in
               let port = 10000 + Random.int 10000 in
               let recv_dst_path = Filename.temp_file "installer" "ssh_pub_key" in
               let decrypted_dst_path =
                 Filename.temp_file "installer" "decrypted_ssh_pub_key"
               in
               print_endline
                 "Transfer the PUBLIC key to the server using one of the \
                  following commands";
               Printf.printf
                 "    cat PUBKEY | gpg -c | ncat %s %d # enter passphrase %s when \
                  prompted\n"
                 ip port otp;
               print_endline "or";
               Printf.printf
                 "    cat PUBKEY | gpg --batch --yes --passphrase %s -c | ncat %s \
                  %d\n"
                 otp ip port;
               print_newline ();
               exec (Printf.sprintf "ncat -lp %d > %s" port recv_dst_path);
               print_newline ();
               print_endline "File received";
               print_endline "Decrypting file";
               try
                 exec
                   (Printf.sprintf
                      "gpg --batch --yes --passphrase %s -o %s --decrypt %s" otp
                      decrypted_dst_path recv_dst_path);
                 let decrypted_file_hash =
                   let res =
                     exec_ret (Printf.sprintf "sha256sum %s" decrypted_dst_path)
                   in
                   res.stdout |> List.hd |> String.split_on_char ' ' |> List.hd
                 in
                 Printf.printf "SHA256 hash of the decrypted file : %s\n"
                   decrypted_file_hash;
                 match
                   ask_yn "Does the hash match the hash of the original file?"
                 with
                 | `Yes -> (
                     let user_name = Option.get config.user_name in
                     let user_ssh_authorized_keys_path =
                       Option.get config.user_ssh_authorized_keys_path
                     in
                     exec (Printf.sprintf "touch %s" user_ssh_authorized_keys_path);
                     Printf.printf "Installing SSH key for user : %s\n" user_name;
                     let key_line =
                       let ic = open_in decrypted_dst_path in
                       Fun.protect
                         ~finally:(fun () -> close_in ic)
                         (fun () -> input_line ic)
                     in
                     let user_ssh_authorized_keys_oc =
                       open_out_gen [ Open_append; Open_text ] 0o600
                         user_ssh_authorized_keys_path
                     in
                     Fun.protect
                       ~finally:(fun () -> close_out user_ssh_authorized_keys_oc)
                       (fun () ->
                          output_string user_ssh_authorized_keys_oc "\n";
                          output_string user_ssh_authorized_keys_oc key_line;
                          output_string user_ssh_authorized_keys_oc "\n");
                     match ask_yn "Do you want to add another SSH key?" with
                     | `Yes -> Retry
                     | `No -> Stop () )
                 | `No -> (
                     print_endline "Incorrect file received";
                     match ask_yn "Do you want to retry?" with
                     | `Yes -> Retry
                     | `No -> Stop () )
               with Exec_fail _ -> (
                   print_endline "Decryption failed";
                   match ask_yn "Do you want to retry?" with
                   | `Yes -> Retry
                   | `No -> Stop () )) );
       config);
  reg ~name:"Ask if set up SaltStack" ~doc:"" (fun answer_store config ->
      let use_saltstack =
        ask_yn_confirm ~answer_store
          "Do you want to use SaltStack for package management?"
        = `Yes
      in
      { config with use_saltstack = Some use_saltstack });
  reg ~name:"Installing SaltStack" ~doc:"" (fun _answer_store config ->
      let use_saltstack = Option.get config.use_saltstack in
      if use_saltstack then Arch_chroot.install [ "salt" ];
      config);
  reg ~name:"Generating SaltStack execution script" ~doc:""
    (fun _answer_store config ->
       let use_saltstack = Option.get config.use_saltstack in
       if use_saltstack then (
         let dst_path =
           concat_file_names
             [
               Config.root_mount_point;
               Config.oali_files_dir_path;
               Config.salt_exec_script_name;
             ]
         in
         let script = Salt_exec_script_template.gen_no_usb_key () in
         let oc = open_out dst_path in
         Fun.protect
           ~finally:(fun () -> close_out oc)
           (fun () -> output_string oc script);
         Unix.chmod dst_path 0o600 );
       config);
  reg ~name:"Git cloning oali-profiles repo into current directory" ~doc:""
    (fun answer_store config ->
       let use_saltstack = Option.get config.use_saltstack in
       if use_saltstack then (
         Printf.printf "The default oali-profiles repo URL is :\n";
         Printf.printf "  %s\n" Config.oali_profiles_repo_url;
         print_newline ();
         let oali_profiles_repo_url =
           if
             ask_yn_confirm ~answer_store
               "Do you want to use a custom repo instead?"
             = `Yes
           then
             ask_string_confirm ~is_valid:not_empty ~answer_store
               "Please enter url"
           else Config.oali_profiles_repo_url
         in
         let oali_profiles_repo_name =
           String.split_on_char '/' oali_profiles_repo_url |> List.rev |> List.hd
         in
         FileUtil.(rm ~force:Force ~recurse:true [ oali_profiles_repo_name ]);
         exec (Printf.sprintf "git clone %s" oali_profiles_repo_url);
         {
           config with
           oali_profiles_repo_url = Some oali_profiles_repo_url;
           oali_profiles_repo_name = Some oali_profiles_repo_name;
         } )
       else config);
  reg ~name:"Select profile to use" ~doc:"" (fun _answer_store config ->
      let use_saltstack = Option.get config.use_saltstack in
      if use_saltstack then
        let dir = Option.get config.oali_profiles_repo_name in
        let profiles =
          Sys.readdir dir |> Array.to_list
          |> List.filter (fun name ->
              Sys.is_directory (Filename.concat dir name))
          |> List.filter (fun name ->
              Core_kernel.String.sub ~pos:0 ~len:1 name <> ".")
        in
        match profiles with
        | [] ->
          failwith "Cloned repository does not contain profile directories"
        | _ ->
          let profile = pick_choice_value profiles in
          { config with oali_profile = Some profile }
      else config);
  reg ~name:"Copying SaltStack files" ~doc:"" (fun _answer_store config ->
      let use_saltstack = Option.get config.use_saltstack in
      ( if use_saltstack then
          let salt_files_path =
            concat_file_names
              [
                Option.get config.oali_profiles_repo_name;
                Option.get config.oali_profile;
                "saltstack";
              ]
          in
          let folders =
            Sys.readdir salt_files_path
            |> Array.to_list
            |> List.map (fun s -> concat_file_names [ salt_files_path; s ])
          in
          FileUtil.cp ~recurse:true folders
            (Filename.concat Config.root_mount_point "srv") );
      config);
  reg ~name:"Customising SaltStack files" ~doc:"" (fun _answer_store config ->
      let use_saltstack = Option.get config.use_saltstack in
      ( if use_saltstack then
          let user_name = Option.get config.user_name in
          let dst_path =
            concat_file_names
              [ Config.root_mount_point; "srv"; "pillar"; "user.sls" ]
          in
          let script = User_sls_template.gen ~user_name in
          let oc = open_out dst_path in
          Fun.protect
            ~finally:(fun () -> close_out oc)
            (fun () -> output_string oc script) );
      config);
  reg ~name:"Generating setup note" ~doc:"" (fun _answer_store config ->
      let use_saltstack = Option.get config.use_saltstack in
      let use_usb_key =
        Option.get config.disk_layout_choice
        = Disk_layout.Sys_part_plus_usb_drive
      in
      let dst_path =
        concat_file_names
          [
            Config.root_mount_point;
            Config.oali_files_dir_path;
            Config.oali_setup_note_name;
          ]
      in
      let note = Oali_setup_note_template.gen ~use_saltstack ~use_usb_key in
      let oc = open_out dst_path in
      Fun.protect
        ~finally:(fun () -> close_out oc)
        (fun () -> output_string oc note);
      config);
  reg ~name:"Setting oali files permissions" ~doc:""
    (fun _answer_store config ->
       let path =
         concat_file_names
           [ Config.root_mount_point; Config.oali_files_dir_path ]
       in
       exec (Printf.sprintf "chmod 700 %s/*" path);
       config);
  reg ~name:"Asking if unmount partitions" ~doc:"" (fun _answer_store config ->
      let do_unmount = ask_yn "Do you want to unmount partitions?" = `Yes in
      { config with do_unmount = Some do_unmount });
  reg ~name:"Unmounting partitions" ~doc:"" (fun _answer_store config ->
      ( if Option.get config.do_unmount then
          let disk_layout = Option.get config.disk_layout in
          Disk_layout.unmount disk_layout );
      config);
  reg ~name:"Asking if shutdown" ~doc:"" (fun _answer_store config ->
      if Option.get config.do_unmount then
        let do_shutdown = ask_yn "Do you want to shutdown?" = `Yes in
        { config with do_shutdown = Some do_shutdown }
      else (
        print_endline "Shutdown skipped";
        config ));
  reg ~name:"Shutting down" ~doc:"" (fun _answer_store config ->
      if
        Option.get config.do_unmount
        && Option.value ~default:false config.do_shutdown
      then exec "poweroff"
      else print_endline "Shutdown skipped";
      config);
  Task_book.run task_book
