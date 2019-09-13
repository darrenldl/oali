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
   *             ask_yn_end_retry ~ret:editor "Is the choice correct?"
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
  reg ~name:"Pick disk layout" (fun config ->
      let parts = Disk_utils.part_list () in
      let choice = pick_choice parts in
      print_int choice;
      config
    );
  Task_book.run task_book
