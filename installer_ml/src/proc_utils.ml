type process_status = Unix.process_status

type exec_result =
  { command : string array
  ; status : process_status
  ; stdout : string }

let exec command : exec_result Lwt.t =
  let p = Lwt_process.open_process_in ("", command) in
  let%lwt status = p#status in
  let%lwt stdout = Lwt_io.read p#stdout in
  Lwt.return {command; status; stdout}

let assert_ok res = assert (res.status = WEXITED 0)
