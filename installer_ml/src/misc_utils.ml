let do_and_ask_retry_if_fail ?(action_name = "") (f : unit -> ('a, 'b) result) =
  let rec aux f =
    match f () with
    | Ok x -> Ok x
    | Error x ->
      Printf.printf "Action %s failed, do you want to retry?" action_name
  in
