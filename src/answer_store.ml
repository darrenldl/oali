type t = (string, string) Hashtbl.t

let create () = Hashtbl.create 100

let to_json (t : t) : Yojson.Basic.t =
  let l =
    t
    |> Hashtbl.to_seq
    |> Seq.map (fun (k, v) ->
        (k, `String v)
      )
    |> List.of_seq
  in
  `Assoc l

let to_file fname (t : t) =
  Yojson.Basic.to_file fname (to_json t)

let of_json (x : Yojson.Basic.t) : t =
  match x with
  | `Assoc l ->
    let t = create () in
    List.iter (fun (k, v) ->
        match v with
        | `String v ->
          Hashtbl.add t k v
        | _ -> failwith "Unexpected case"
      ) l;
    t
  | _ -> failwith "Unexpected case"

let from_file fname : t =
  Yojson.Basic.from_file fname
  |> of_json
