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

let ask_yn_end_retry ~(ret:'a) prompt =
  match ask_yn prompt with
  | Yes ->
    Stop ret
  | No ->
    Retry

let ask_int ?upper_bound_exc prompt =
  ask_string ~is_valid:(fun s -> try
                           let x = int_of_string s in
                           match upper_bound_exc with
                           | None -> true
                           | Some ub -> x < ub
                           with Failure _ -> false) prompt
  |> int_of_string

let tell_press_enter () =
  print_newline ();
  print_string "Please press enter to continue";
  read_line () |> ignore;
  print_newline ()

let pick_choice choices =
  print_endline "Options";
  print_newline ();
  List.iteri (fun i s ->
      Printf.printf "    %d    %s\n" i s
    ) choices;
  print_newline ();
  let choice_count = List.length choices in
  ask_int ~upper_bound_exc:choice_count "Enter choice"
