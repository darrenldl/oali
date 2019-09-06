type process_status = Unix.process_status

type exec_result =
  { command : string array
  ; status : process_status
  ; stdout : string }

let exec_result_is_ok res = res.status = WEXITED 0

let exec command : (exec_result, exec_result) result Lwt.t =
  let p = Lwt_process.open_process_in ("", command) in
  let%lwt status = p#status in
  let%lwt stdout = Lwt_io.read p#stdout in
  let res = {command; status; stdout} in
  if exec_result_is_ok res then Lwt.return (Ok res) else Lwt.return (Error res)

let exec_with_stdin command :
  Lwt_io.output_channel * (unit -> (exec_result, exec_result) result Lwt.t) =
  let p = Lwt_process.open_process_full ("", command) in
  ( p#stdin
  , fun () ->
    let%lwt status = p#status in
    let%lwt stdout = Lwt_io.read p#stdout in
    let res = {command; status; stdout} in
    if exec_result_is_ok res then Lwt.return (Ok res)
    else Lwt.return (Error res) )
