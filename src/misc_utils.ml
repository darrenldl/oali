type 'a retry =
  | Stop of 'a
  | Retry

type yn =
  [ `Yes
  | `No
  ]

let not_empty s = s <> ""

module Internal = struct
  let retry ~answer_store (f : unit -> 'a retry) : 'a =
    let rec aux f =
      match f () with
      | Stop x -> x
      | Retry ->
        Option.iter
          (fun store ->
             print_endline "Wiping answer store";
             Hashtbl.reset store)
          answer_store;
        aux f
    in
    aux f

  let ask_string ?(is_valid = fun _ -> true) ~(no_echo : bool option)
      ~(answer_store : (string, string) Hashtbl.t option) prompt =
    let no_echo = Option.value ~default:false no_echo in
    let answer =
      match answer_store with
      | None -> None
      | Some answer_store -> Hashtbl.find_opt answer_store prompt
    in
    match answer with
    | Some x ->
      Printf.printf "%s -> using stored answer : %s\n" prompt x;
      x
    | None ->
      retry ~answer_store:None (fun () ->
          Printf.printf "%s : " prompt;
          let tios = Unix.(tcgetattr stdin) in
          if no_echo then (
            tios.c_echo <- false;
            Unix.(tcsetattr stdin TCSANOW tios) );
          let res = try read_line () with End_of_file -> "" in
          if no_echo then (
            print_newline ();
            tios.c_echo <- true;
            Unix.(tcsetattr stdin TCSANOW tios) );
          if is_valid res then (
            Option.iter
              (fun store -> Hashtbl.add store prompt res)
              answer_store;
            Stop res )
          else (
            print_endline "Invalid answer, please try again";
            Retry ))

  let ask_yn ~answer_store prompt =
    retry ~answer_store (fun () ->
        let s =
          ask_string ~is_valid:not_empty ~no_echo:None ~answer_store
            (Printf.sprintf "%s y/n" prompt)
          |> String.lowercase_ascii
        in
        let len = String.length s in
        let yes = "yes" in
        let yes_len = String.length yes in
        let no = "no" in
        let no_len = String.length no in
        let y = String.sub yes 0 (min yes_len len) in
        let n = String.sub no 0 (min no_len len) in
        if s = y && len <= yes_len then Stop `Yes
        else if s = n && len <= no_len then Stop `No
        else Retry)

  let ask_yn_end_retry ~(ret : 'a) ~answer_store prompt =
    match ask_yn ~answer_store prompt with `Yes -> Stop ret | `No -> Retry

  let ask_uint ~lower_bound ~upper_bound_exc ~answer_store prompt =
    let lower_bound = lower_bound |> Option.value ~default:0 |> max 0 in
    let prompt =
      prompt
      ^
      match upper_bound_exc with
      | None -> Printf.sprintf " (min : %d)" lower_bound
      | Some ub -> Printf.sprintf " (min : %d, max exc : %d)" lower_bound ub
    in
    ask_string
      ~is_valid:(fun s ->
          match int_of_string_opt s with
          | None -> false
          | Some x -> (
              lower_bound <= x
              && match upper_bound_exc with None -> true | Some ub -> x < ub ))
      ~no_echo:None ~answer_store prompt
    |> int_of_string
end

let ask_string ?(is_valid = fun _ -> true) ?no_echo ?answer_store prompt =
  Internal.ask_string ~is_valid ~no_echo ~answer_store prompt

let ask_yn ?answer_store prompt = Internal.ask_yn ~answer_store prompt

let ask_yn_end_retry ~(ret : 'a) ?answer_store prompt =
  Internal.ask_yn_end_retry ~ret ~answer_store prompt

let ask_uint ?lower_bound ?upper_bound_exc ?answer_store prompt =
  Internal.ask_uint ~lower_bound ~upper_bound_exc ~answer_store prompt

let tell_press_enter () =
  print_newline ();
  print_string "Please press enter to continue";
  read_line () |> ignore;
  print_newline ()

let confirm_answer_is_correct () = ask_yn "Is the answer correct?"

let confirm_answer_is_correct_end_retry ~ret =
  ask_yn_end_retry ~ret "Is the answer correct?"

let ask_yn_confirm ?answer_store prompt =
  Internal.retry ~answer_store (fun () ->
      let ret = Internal.ask_yn ~answer_store prompt in
      confirm_answer_is_correct_end_retry ~ret)

let ask_string_confirm ?(is_valid = fun _ -> true) ?no_echo ?answer_store prompt
  =
  Internal.retry ~answer_store (fun () ->
      let ret = Internal.ask_string ~is_valid ~no_echo ~answer_store prompt in
      confirm_answer_is_correct_end_retry ~ret)

let ask_uint_confirm ?lower_bound ?upper_bound_exc ?answer_store prompt =
  Internal.retry ~answer_store (fun () ->
      let ret =
        Internal.ask_uint ~lower_bound ~upper_bound_exc ~answer_store prompt
      in
      confirm_answer_is_correct_end_retry ~ret)

let pick_choice_num ?(confirm = true) ?(header = "Options")
    (choices : string list) : int =
  Internal.retry ~answer_store:None (fun () ->
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
        let choice_num =
          ask_uint ~upper_bound_exc:choice_count "Enter choice"
        in
        if confirm then confirm_answer_is_correct_end_retry ~ret:choice_num
        else Stop choice_num)

let pick_choice_kv (type a) ?(confirm = true) ?(header = "Options")
    (choices : (string * a) list) : a =
  let keys, values = List.split choices in
  let choice_num = pick_choice_num ~confirm ~header keys in
  List.nth values choice_num

let pick_choice_value ?(confirm = true) ?(header = "Options")
    (choices : string list) : string =
  let choice_num = pick_choice_num ~confirm ~header choices in
  List.nth choices choice_num

let pick_choice_grouped_num ?(confirm = true) ?(first_header = "Options")
    ?(second_header = "Options") (choices : (string * string list) list) =
  Internal.retry ~answer_store:None (fun () ->
      let first_layer = List.map (fun (x, _) -> x) choices in
      let choice1 =
        pick_choice_num ~confirm:false ~header:first_header first_layer
      in
      let second_layer = List.nth choices choice1 |> fun (_, l) -> l in
      let choice2 =
        pick_choice_num ~confirm:false ~header:second_header second_layer
      in
      if confirm then confirm_answer_is_correct_end_retry ~ret:(choice1, choice2)
      else Stop (choice1, choice2))

let pick_choice_grouped_kv (type a) ?(confirm = true)
    ?(first_header = "Options") ?(second_header = "Options")
    (choices : (string * (string * a) list) list) : a =
  let keys =
    List.map (fun (k, l) -> (k, List.map (fun (k, _) -> k) l)) choices
  in
  let c1, c2 =
    pick_choice_grouped_num ~confirm ~first_header ~second_header keys
  in
  let _, layer2 = List.nth choices c1 in
  let _, value = List.nth layer2 c2 in
  value

let pick_choice_grouped_value ?(confirm = true) ?(first_header = "Options")
    ?(second_header = "Options") (choices : (string * string list) list) :
  string =
  let c1, c2 =
    pick_choice_grouped_num ~confirm ~first_header ~second_header choices
  in
  let _, layer2 = List.nth choices c1 in
  List.nth layer2 c2

let retry ?answer_store (f : unit -> 'a retry) : 'a =
  Internal.retry ~answer_store f

let list_no_nth l n =
  let rec aux acc l n =
    match l with
    | [] -> List.rev acc
    | x :: xs ->
      if n = 0 then aux acc xs (pred n) else aux (x :: acc) xs (pred n)
  in
  aux [] l n

let print_boxed_msg s =
  let len = String.length s + 4 in
  let line = String.concat "" [ "+"; String.make (len - 2) '-'; "+" ] in
  print_endline line;
  Printf.printf "| %s |\n" s;
  print_endline line

let concat_file_names names =
  let splits =
    names
    |> List.map (fun s ->
        Core_kernel.String.Escaping.split s ~on:'/' ~escape_char:'\\')
    |> List.concat
    |> List.filter not_empty
  in
  let res = String.concat Filename.dir_sep splits in
  match names with
  | [] -> res
  | x :: _ -> if String.sub x 0 1 = "/" then "/" ^ res else res

let calc_frac ~max_frac ~value ~total =
  assert (max_frac >= 0.0);
  assert (max_frac <= 1.0);
  min (value /. total) max_frac

let frac_to_perc frac : int = int_of_float (Float.round (frac *. 100.0))
