let filter_map_lines ~file (f : string -> string list) =
  let rec aux ic oc f =
    let line =
      try
        Some (input_line ic)
      with
        End_of_file -> None
    in
    match line with
    | None -> ()
    | Some s ->
      let new_s_s = f s in
      List.iter (fun new_s ->
          output_string oc (new_s ^ "\n");
        ) new_s_s;
      aux ic oc f
  in
  let tmp_dir = Filename.get_temp_dir_name () in
  let dst_name = "installer" ^ file in
  let dst_oc = open_out dst_name in
  let src_ic = open_in file in
  Fun.protect ~finally:(fun () -> close_out dst_oc)
    (fun () ->
       Fun.protect ~finally:(fun () -> close_in src_ic)
         (fun () ->
            aux src_ic dst_oc f
         )
    );
  Sys.rename (Filename.concat tmp_dir dst_name) file
