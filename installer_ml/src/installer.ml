let () =
  let config = Task_config.create () in
  let task_book = Task_book.make config in
  Task_book.register task_book ~name:"ls" (fun _config ->
      let stdin, f = Proc_utils.exec_ret_with_stdin "ls" in
      output_string stdin "abcd";
      let res = f () in
      print_endline "done";
      List.iter print_endline res.stdout);
  Task_book.run task_book;
  try ()
  with Proc_utils.Exec_fail r -> print_endline (Proc_utils.report_failure r)
