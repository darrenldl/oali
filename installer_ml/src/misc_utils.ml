(* let do_and_ask_retry_if_fail ?(action_name = "") (f : unit -> ('a, 'b) result) =
 *   let rec aux f =
 *     match f () with
 *     | Ok x -> Ok x
 *     | Error x ->
 *       Printf.printf "Action %s failed, do you want to retry?" action_name
 *   in *)

type 'a retry =
  | Stop of 'a
  | Retry

type yn =
  | Yes
  | No

let retry (f : unit -> 'a retry) : 'a =
  let rec aux f = match f () with Stop x -> x | Retry -> aux f in
  aux f

let ask_string ?(is_valid = fun _ -> true) prompt =
  retry (fun () ->
      Printf.printf "%s : " prompt;
      let res = read_line () in
      if is_valid res then Stop res
      else (
        print_endline "Invalid answer, please try again";
        Retry ))

let ask_yn prompt =
  retry (fun () ->
      let s =
        ask_string (Printf.sprintf "%s y/n" prompt) |> String.lowercase_ascii
      in
      let len = String.length s in
      let y = String.sub "yes" 0 len in
      let n = String.sub "no" 0 len in
      if s = y then Stop Yes else if s = n then Stop No else Retry)
