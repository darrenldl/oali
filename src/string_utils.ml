let tail_w_pos ~pos s =
  let s_len = String.length s in
  String.sub s pos (s_len - pos)

let tail_w_len ~len s =
  let s_len = String.length s in
  String.sub s (s_len - len) len

let strip_tail_num s =
  let pos = ref None in
  String.iteri
    (fun i c ->
       if Misc_utils.is_digit c then
         pos := match !pos with None -> Some i | Some x -> Some x)
    s;
  match !pos with None -> s | Some pos -> String.sub s 0 pos

let get_tail_num s =
  let len = String.length s in
  let pos = ref None in
  String.iteri
    (fun i c ->
       if Misc_utils.is_digit c then
         pos := match !pos with None -> Some i | Some x -> Some x)
    s;
  match !pos with
  | None -> None
  | Some pos -> Some (String.sub s pos (len - pos) |> int_of_string)

let strip_prefix ~prefix s =
  let prefix_len = String.length prefix in
  let s_len = String.length s in
  if s_len < prefix_len then s
  else
    let sub = String.sub s 0 prefix_len in
    if sub = prefix then String.sub s prefix_len s_len else s

let escaping_split ?(escape_char = '\\') ~on s =
  let acc = ref [] in
  let rec aux seg_start i =
    if i < String.length s then (
      let escaped =
        i > 1 && s.[i-1] = escape_char
      in
      if escaped then
        aux seg_start (succ i)
      else (
        if s.[i] = on then (
          acc := (String.sub s seg_start (i - seg_start)) :: !acc;
          aux (succ i) (succ i)
        ) else
          aux seg_start (succ i)
      )
    ) else (
      acc := (String.sub s seg_start (i - seg_start)) :: !acc
    )
  in
  aux 0 0;
  List.rev !acc

let concat_file_names names =
  let splits =
    names
    |> List.map (fun s ->
        escaping_split ~on:'/' ~escape_char:'\\' s)
    |> List.concat
    |> List.filter Misc_utils.not_empty
  in
  let res = String.concat Filename.dir_sep splits in
  match names with
  | [] -> res
  | x :: _ -> if String.sub x 0 1 = "/" then "/" ^ res else res
