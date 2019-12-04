let filter_map_fold_lines ~file (acc : 'a)
    (f : 'a -> string -> 'a * string list) =
  let rec aux ic oc acc f =
    let line = try Some (input_line ic) with End_of_file -> None in
    match line with
    | None ->
      acc
    | Some s ->
      let new_acc, new_s_s = f acc s in
      List.iter (fun new_s -> output_string oc (new_s ^ "\n")) new_s_s;
      aux ic oc new_acc f
  in
  let dst_path = Filename.temp_file "installer" (Filename.basename file) in
  let dst_oc = open_out dst_path in
  let src_ic = open_in file in
  let acc =
    Fun.protect
      ~finally:(fun () -> close_out dst_oc)
      (fun () ->
         Fun.protect
           ~finally:(fun () -> close_in src_ic)
           (fun () -> aux src_ic dst_oc acc f))
  in
  FileUtil.mv dst_path file; acc

let filter_map_lines ~file (f : string -> string list) =
  filter_map_fold_lines ~file () (fun () s -> ((), f s))
