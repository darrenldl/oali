open Proc_utils
open Misc_utils

let () =
  let config = Task_config.create () in
  let task_book = Task_book.make config in
  let reg ~name task = Task_book.register task_book ~name task in
  (* reg ~name:"ls" (fun config ->
   *     let stdin, f = Proc_utils.exec_ret_with_stdin "ls" in
   *     output_string stdin "abcd";
   *     let res = f () in
   *     print_endline "done";
   *     List.iter print_endline res.stdout;
   *   config); *)
  (* reg ~name:"Update time" (fun config ->
   *     exec "timedatectl set-ntp true";
   *     config
   *   ); *)
  (* reg ~name:"Pick editor" (fun config ->
   *     let editor =
   *       retry (fun () ->
   *           let editor =
   *             ask_string
   *               ~is_valid:(fun s -> s <> "")
   *               "Please enter editor command"
   *           in
   *           try
   *             exec (Printf.sprintf "hash %s" editor);
   *             confirm_answer_is_correct_end_retry ~ret:editor
   *           with Exec_fail _ ->
   *             print_endline
   *               "Failed to find editor, please pick a different one";
   *             Retry)
   *     in
   *     {config with editor = Some editor}); *)
  (* reg ~name:"Configure mirrorlist" (fun config ->
   *     let editor = Option.get config.editor in
   *     Printf.printf "Editor %s will be used for editing mirror list\n" editor;
   *     tell_press_enter ();
   *     retry (fun () ->
   *         exec_no_capture (Printf.sprintf "%s /etc/pacman.d/mirrorlist" editor);
   * 
   *         ask_yn_end_retry ~ret:() "Finished editing?"
   *       );
   *     config
   *   ); *)
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
  reg ~name:"Configure disk setup parameters" (fun config ->
      let open Disk_layout in
      let mapper_name_boot = "crypt_boot" in
      let mapper_name_root = "crypt_root" in
      let is_efi_mode = Sys.file_exists "/sys/firmware/efi" in
      if is_efi_mode then
        print_boxed_msg
          "System is in EFI mode, launching EFI partition selection menu"
      else
        print_boxed_msg
          "System is in BIOS mode, EFI partition selection skipped";
      match Option.get config.disk_layout_choice with
      | Single_disk ->
        let disks = Disk_utils.list_disks () in
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
        let encrypt = ask_yn "Enable encryption?" = Yes in
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
          let esp_part =
            Some (make_part ~path:esp_part_path (Plain_FS Fat32))
          in
          if encrypt then
            let boot_key =
              ask_string_confirm
                ~is_valid:(fun x -> x <> "")
                "Please enter passphrase for encryption"
            in
            let boot_part =
              make_part ~path:boot_part_path
                (Luks
                   (make_luks ~key:boot_key ~version:LuksV1 Ext4
                      ~mapper_name:mapper_name_boot))
            in
            let sys_part =
              make_part ~path:sys_part_path
                (Luks (make_luks Ext4 ~mapper_name:mapper_name_root))
            in
            let disk_layout = make_layout ~esp_part ~boot_part ~sys_part in
            {config with disk_layout = Some disk_layout}
          else
            let boot_part = make_part ~path:boot_part_path (Plain_FS Ext4) in
            let sys_part = make_part ~path:sys_part_path (Plain_FS Ext4) in
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
          if encrypt then
            let boot_key =
              ask_string_confirm
                ~is_valid:(fun x -> x <> "")
                "Please enter passphrase for encryption"
            in
            let boot_part =
              make_part ~path:boot_part_path
                (Luks
                   (make_luks ~key:boot_key ~version:LuksV1 Ext4
                      ~mapper_name:mapper_name_boot))
            in
            let sys_part =
              make_part ~path:sys_part_path
                (Luks (make_luks Ext4 ~mapper_name:mapper_name_root))
            in
            let disk_layout =
              make_layout ~esp_part:None ~boot_part ~sys_part
            in
            {config with disk_layout = Some disk_layout}
          else
            let boot_part = make_part ~path:boot_part_path (Plain_FS Ext4) in
            let sys_part = make_part ~path:sys_part_path (Plain_FS Ext4) in
            let disk_layout =
              make_layout ~esp_part:None ~boot_part ~sys_part
            in
            {config with disk_layout = Some disk_layout}
      | Sys_part_plus_boot_plus_maybe_EFI ->
        let parts = Disk_utils.list_parts () in
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
        let encrypt = ask_yn "Enable encryption?" = Yes in
        let esp_part =
          Option.map
            (fun path -> make_part ~path (Plain_FS Fat32))
            esp_part_path
        in
        if encrypt then
          let boot_key =
            ask_string_confirm
              ~is_valid:(fun x -> x <> "")
              "Please enter passphrase for encryption"
          in
          let boot_part =
            make_part ~path:boot_part_path
              (Luks
                 (make_luks ~key:boot_key ~version:LuksV1 Ext4
                    ~mapper_name:mapper_name_boot))
          in
          let sys_part =
            make_part ~path:sys_part_path
              (Luks (make_luks Ext4 ~mapper_name:mapper_name_root))
          in
          let disk_layout = make_layout ~esp_part ~boot_part ~sys_part in
          {config with disk_layout = Some disk_layout}
        else
          let boot_part = make_part ~path:boot_part_path (Plain_FS Ext4) in
          let sys_part = make_part ~path:sys_part_path (Plain_FS Ext4) in
          let disk_layout = make_layout ~esp_part ~boot_part ~sys_part in
          {config with disk_layout = Some disk_layout}
    );
  Task_book.run task_book
