let exec command : (Unix.process_status * string) Lwt.t =
  let p = Lwt_process.open_process_in command in
  let%lwt status = p#status in
  let%lwt output = Lwt_io.read p#stdout in
  Lwt.return (status, output)
