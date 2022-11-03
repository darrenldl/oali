type process_status = Unix.process_status

type exec_result = {
  cmd : string;
  status : process_status;
  stdout : string list;
  stderr : string list;
}

exception Exec_fail of exec_result

let process_status_to_string s =
  let open Unix in
  match s with
  | WEXITED i -> Printf.sprintf "exited %d" i
  | WSIGNALED i -> Printf.sprintf "signaled %d" i
  | WSTOPPED i -> Printf.sprintf "stopped %d" i

let report_failure res =
  Printf.sprintf "Exec failed: %s, status: %s\nstdout :\n%s\nstderr :\n%s"
    res.cmd
    (process_status_to_string res.status)
    (String.concat "\n" res.stdout)
    (String.concat "\n" res.stderr)

let exec_result_is_ok res = res.status = WEXITED 0

let input_all_lines in_chan =
  let rec aux in_chan acc =
    let stop, acc =
      try (false, input_line in_chan :: acc) with End_of_file -> (true, acc)
    in
    if stop then acc else aux in_chan acc
  in
  List.rev (aux in_chan [])

let exec_ret_no_exn cmd : (exec_result, exec_result) result =
  let stdout_chan, stdin_chan, stderr_chan = Unix.open_process_full cmd [||] in
  let stdout = input_all_lines stdout_chan in
  let stderr = input_all_lines stderr_chan in
  let status = Unix.close_process_full (stdout_chan, stdin_chan, stderr_chan) in
  let res = { cmd; status; stdout; stderr } in
  if exec_result_is_ok res then Ok res else Error res

let exec_ret cmd : exec_result =
  match exec_ret_no_exn cmd with Ok r -> r | Error r -> raise (Exec_fail r)

let exec cmd = exec_ret cmd |> ignore

let exec_ret_with_stdin_no_exn cmd :
  out_channel * (unit -> (exec_result, exec_result) result) =
  let stdout_chan, stdin_chan, stderr_chan = Unix.open_process_full cmd [||] in
  ( stdin_chan,
    fun () ->
      close_out stdin_chan;
      let stdout = input_all_lines stdout_chan in
      let stderr = input_all_lines stderr_chan in
      let status =
        Unix.close_process_full (stdout_chan, stdin_chan, stderr_chan)
      in
      let res = { cmd; status; stdout; stderr } in
      if exec_result_is_ok res then Ok res else Error res )

let exec_ret_with_stdin cmd : out_channel * (unit -> exec_result) =
  let stdin_chan, f = exec_ret_with_stdin_no_exn cmd in
  let f () = match f () with Ok r -> r | Error r -> raise (Exec_fail r) in
  (stdin_chan, f)

let exec_with_stdin cmd =
  let stdin_chan, f = exec_ret_with_stdin cmd in
  let f () = f () |> ignore in
  (stdin_chan, f)

let exec_ret_no_capture_no_exn cmd =
  let status = Unix.system cmd in
  let res = { cmd; status; stdout = []; stderr = [] } in
  if exec_result_is_ok res then Ok res else Error res

let exec_ret_no_capture cmd =
  match exec_ret_no_capture_no_exn cmd with
  | Ok r -> r
  | Error r -> raise (Exec_fail r)

let exec_no_capture cmd = exec_ret_no_capture cmd |> ignore

let clear () = exec_no_capture "clear"

let pacman s = exec_no_capture (Printf.sprintf "pacman --noconfirm %s" s)

let install pkgs = pacman (Printf.sprintf "-S %s" (String.concat " " pkgs))
