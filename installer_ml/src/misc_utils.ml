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
      let res = try read_line () with End_of_file -> "" in
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
      let yes = "yes" in
      let yes_len = String.length yes in
      let no = "no" in
      let no_len = String.length no in
      let y = String.sub yes 0 (min yes_len len) in
      let n = String.sub no 0 (min no_len len) in
      if s = y && len <= yes_len then Stop Yes
      else if s = n && len <= no_len then Stop No
      else Retry)

let ask_yn_end_retry ~(ret : 'a) prompt =
  match ask_yn prompt with Yes -> Stop ret | No -> Retry

let ask_uint ?upper_bound_exc prompt =
  ask_string
    ~is_valid:(fun s ->
        match int_of_string_opt s with
        | None ->
          false
        | Some x -> (
            match upper_bound_exc with None -> x >= 0 | Some ub -> x < ub ))
    prompt
  |> int_of_string

let tell_press_enter () =
  print_newline ();
  print_string "Please press enter to continue";
  read_line () |> ignore;
  print_newline ()

let confirm_answer_is_correct () = ask_yn "Is the answer correct?"

let confirm_answer_is_correct_end_retry ~ret =
  ask_yn_end_retry ~ret "Is the answer correct?"

let ask_yn_confirm prompt =
  retry (fun () ->
      let ret = ask_yn prompt in
      confirm_answer_is_correct_end_retry ~ret)

let ask_string_confirm ?(is_valid = fun _ -> true) prompt =
  retry (fun () ->
      let ret = ask_string ~is_valid prompt in
      confirm_answer_is_correct_end_retry ~ret)

let pick_choice ?(confirm = true) ?(header = "Options") choices =
  retry (fun () ->
      assert (List.length choices > 0);
      print_endline header;
      print_newline ();
      List.iteri (fun i s -> Printf.printf "%5d    %s\n" i s) choices;
      print_newline ();
      let choice_count = List.length choices in
      if choice_count = 1 then (
        print_endline "Selected the only choice automatically";
        Stop 0 )
      else
        let choice = ask_uint ~upper_bound_exc:choice_count "Enter choice" in
        if confirm then confirm_answer_is_correct_end_retry ~ret:choice
        else Stop choice)

let pick_choice_grouped ?(confirm = true) ?(first_header = "Options")
    ?(second_header = "Options") (choices : ('a * 'b list) list) =
  retry (fun () ->
      let first_layer = List.map (fun (k, _) -> k) choices in
      let choice1 =
        pick_choice ~confirm:false ~header:first_header first_layer
      in
      let second_layer = List.nth choices choice1 |> fun (_, l) -> l in
      let choice2 =
        pick_choice ~confirm:false ~header:second_header second_layer
      in
      if confirm then
        confirm_answer_is_correct_end_retry ~ret:(choice1, choice2)
      else Stop (choice1, choice2))

let list_no_nth l n =
  let rec aux acc l n =
    match l with
    | [] ->
      List.rev acc
    | x :: xs ->
      if n = 0 then aux acc xs (pred n) else aux (x :: acc) xs (pred n)
  in
  aux [] l n

let print_boxed_msg s =
  let len = String.length s + 4 in
  let line = String.concat "" ["+"; String.make (len - 2) '-'; "+"] in
  print_endline line; Printf.printf "| %s |\n" s; print_endline line

let concat_file_names names =
  let splits =
    names
    |> List.map (fun s ->
        Core_kernel.String.Escaping.split s ~on:'/' ~escape_char:'\\')
    |> List.concat
    |> List.filter (fun s -> s <> "")
  in
  let res = String.concat Filename.dir_sep splits in
  match names with
  | [] ->
    res
  | x :: _ ->
    if String.sub x 0 1 = "/" then "/" ^ res else res

let calc_perc ~value ~max = min (value * 100 / max) max
