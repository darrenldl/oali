type process_status = Unix.process_status

type exec_result =
  { prog : string
  ; args : string array
  ; status : process_status
  ; stdout : string list }

let exec_result_is_ok res = res.status = WEXITED 0

let input_all_lines in_chan =
  let rec aux in_chan acc =
    let stop, acc =
      try
        false, input_line in_chan :: acc
      with
      | End_of_file -> true, acc
    in
    if stop then
      acc
    else
      aux in_chan acc
  in
  List.rev (aux in_chan [])

let exec prog args : (exec_result, exec_result) result =
  let stdout_chan = Unix.open_process_args_in prog args in
  let stdout = input_all_lines stdout_chan in
  let status = Unix.close_process_in stdout_chan in
  let res = {prog; args; status; stdout} in
  if exec_result_is_ok res then Ok res else Error res

let exec_with_stdin prog args :
  out_channel * (unit -> (exec_result, exec_result) result Lwt.t) =
  let (stdout_chan, stdin_chan) = Unix.open_process_args prog args in
  ( stdin_chan
  , fun () ->
    let stdout = input_all_lines stdout_chan in
    let status = Unix.close_process (stdout_chan, stdin_chan) in
    let res = {prog; args; status; stdout} in
    if exec_result_is_ok res then Lwt.return (Ok res)
    else Lwt.return (Error res) )
