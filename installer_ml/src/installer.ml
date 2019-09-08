let () =
  try Proc_utils.exec "ls"
  with Proc_utils.Exec_fail r -> print_endline (Proc_utils.report_failure r)
