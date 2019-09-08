type process_status = Unix.process_status

type exec_result =
  { prog : string
  ; args : string array
  ; status : process_status
  ; stdout : string list }

exception Exec_error of exec_result

let report_failure res =
  Printf.sprintf "Exec failed : %s %s" res.prog (String.concat " " (Array.to_list res.args))

let exec_result_is_ok res = res.status = WEXITED 0

let input_all_lines in_chan =
  let rec aux in_chan acc =
    let stop, acc =
      try (false, input_line in_chan :: acc) with End_of_file -> (true, acc)
    in
    if stop then acc else aux in_chan acc
  in
  List.rev (aux in_chan [])

let exec_ret_no_exn prog args : (exec_result, exec_result) result =
  let stdout_chan = Unix.open_process_args_in prog args in
  let stdout = input_all_lines stdout_chan in
  let status = Unix.close_process_in stdout_chan in
  let res = {prog; args; status; stdout} in
  if exec_result_is_ok res then Ok res else Error res

let exec_ret prog args : exec_result =
  match exec_ret_no_exn prog args with
  | Ok r -> r
  | Error r -> raise (Exec_error r)

let exec prog args =
  exec_ret prog args |> ignore

let exec_ret_with_stdin_no_exn prog args :
  out_channel * (unit -> (exec_result, exec_result) result ) =
  let stdout_chan, stdin_chan = Unix.open_process_args prog args in
  ( stdin_chan
  , fun () ->
    let stdout = input_all_lines stdout_chan in
    let status = Unix.close_process (stdout_chan, stdin_chan) in
    let res = {prog; args; status; stdout} in
    if exec_result_is_ok res then Ok res else Error res
  )

let exec_ret_with_stdin prog args :
  out_channel * (unit -> exec_result) =
  let stdin_chan, f = exec_ret_with_stdin_no_exn prog args in
  let f = fun () ->
    match f () with
    | Ok r -> r
    | Error r -> raise (Exec_error r)
  in
  (stdin_chan, f)

let exec_with_stdin prog args =
  let stdin_chan, f = exec_ret_with_stdin prog args in
  let f = fun () ->
    f () |> ignore
  in
  (stdin_chan, f)
