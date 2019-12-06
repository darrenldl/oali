type t = (string, string) Hashtbl.t

let normalize_name s =
  s |> String.lowercase_ascii
  |> String.split_on_char ' '
  |> List.map (Core_kernel.String.filter ~f:Core_kernel.Char.is_alphanum)
  |> List.filter (fun s -> s <> "")
  |> String.concat "_"

let task_name_to_file_name ~task_name =
  Misc_utils.concat_file_names
    [ Config.oali_answer_store_dir; normalize_name task_name ]

let create () = Hashtbl.create 100

let to_json (t : t) : Yojson.Basic.t =
  let l =
    t |> Hashtbl.to_seq |> Seq.map (fun (k, v) -> (k, `String v)) |> List.of_seq
  in
  `Assoc l

let write ~task_name (t : t) =
  Proc_utils.exec (Printf.sprintf "mkdir -p %s" Config.oali_answer_store_dir);
  Yojson.Basic.to_file (task_name_to_file_name ~task_name) (to_json t)

let of_json (x : Yojson.Basic.t) : t =
  match x with
  | `Assoc l ->
    let t = create () in
    List.iter
      (fun (k, v) ->
         match v with
         | `String v -> Hashtbl.add t k v
         | _ -> failwith "Unexpected case")
      l;
    t
  | _ -> failwith "Unexpected case"

let load ~task_name : t =
  let fname = task_name_to_file_name ~task_name in
  try
    let t = Yojson.Basic.from_file fname |> of_json in
    (* Printf.printf "Loaded answer store from : %s\n" fname; *)
    t
  with
  | Yojson.Json_error _ ->
    (* Printf.printf "Failed to load answer store from : %s\n" fname; *)
    (* print_endline "Creating new answer store"; *)
    create ()
  | Sys_error _ ->
    (* print_endline "Creating new answer store"; *)
    create ()
