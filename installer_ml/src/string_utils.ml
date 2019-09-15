let tail start s =
  let len = String.length s in
  String.sub s start (len - start)

let strip_tail_num s =
  let pos = ref None in
  String.iteri
    (fun i c ->
       if Core_kernel.Char.is_digit c then
         pos := match !pos with None -> Some i | Some x -> Some x)
    s;
  match !pos with None -> s | Some pos -> String.sub s 0 pos

let get_tail_num s =
  let len = String.length s in
  let pos = ref None in
  String.iteri
    (fun i c ->
       if Core_kernel.Char.is_digit c then
         pos := match !pos with None -> Some i | Some x -> Some x)
    s;
  match !pos with
  | None ->
    None
  | Some pos ->
    Some (String.sub s pos (len - pos) |> int_of_string)
