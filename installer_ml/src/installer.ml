(* open Proc_utils *)
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
        ; ( "system partition + boot stuff on external USB drive"
          , Sys_part_plus_usb_drive ) ]
      in
      let choice_num = pick_choice (List.map (fun (x, _) -> x) choices) in
      let choice = (fun (_, y) -> y) (List.nth choices choice_num) in
      {config with disk_layout_choice = Some choice});
  reg ~name:"Configure disk setup parameters" (fun config ->
      match Option.get config.disk_layout_choice with
      | Single_disk ->
        let disks = Disk_utils.list_disks () in
        let choice = pick_choice ~header:"Disks" disks in
        print_int choice; config
      | Sys_part_plus_boot_plus_maybe_EFI ->
        let parts = Disk_utils.list_parts () in
        let disk_part_tree = Disk_utils.group_parts_by_disks parts in
        let disk_part_tree, sys_part =
          let disk, part =
            pick_choice_grouped
              ~first_header:"Select disk containing the system partition"
              ~second_header:"Select system partition" disk_part_tree
          in
          ( Disk_utils.remove_part_from_tree disk_part_tree disk part
          , Disk_utils.get_part_from_tree disk_part_tree disk part )
        in
        print_endline sys_part;
        let disk_part_tree, boot_part =
          let disk, part =
            pick_choice_grouped
              ~first_header:"Select disk containing the boot partition"
              ~second_header:"Select boot partition" disk_part_tree
          in
          ( Disk_utils.remove_part_from_tree disk_part_tree disk part
          , Disk_utils.get_part_from_tree disk_part_tree disk part )
        in
        print_endline boot_part;
        let _efi_part =
          if Sys.file_exists "/sys/firmware/efi" then (
            print_boxed_msg
              "System is in EFI mode, launching EFI partition selection menu";
            let disk, part =
              pick_choice_grouped
                ~first_header:"Select disk containing the EFI partition"
                ~second_header:"Select EFI partition" disk_part_tree
            in
            Some (Disk_utils.get_part_from_tree disk_part_tree disk part) )
          else (
            print_boxed_msg
              "System is in BIOS mode, EFI partition selection skipped";
            None )
        in
        config
      | Sys_part_plus_usb_drive ->
        config);
  Task_book.run task_book
