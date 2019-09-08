let () =
  try
    let stdin, f = Proc_utils.exec_ret_with_stdin "ls" in
    output_string stdin "abcd";
    let res = f () in
    print_endline "done";
    List.iter print_endline res.stdout
  with Proc_utils.Exec_fail r -> print_endline (Proc_utils.report_failure r)
