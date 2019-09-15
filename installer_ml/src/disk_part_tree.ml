type t = (string * string list) list

module DiskPartMap = Map.Make (struct
    type t = string

    let compare = compare
  end)

let of_parts parts =
  parts
  |> List.map (fun part -> (Disk_utils.part_to_disk part, part))
  |> List.fold_left
    (fun tbl (disk, part) ->
       match DiskPartMap.find_opt disk tbl with
       | None ->
         DiskPartMap.add disk [part] tbl
       | Some l ->
         DiskPartMap.add disk (part :: l) tbl)
    DiskPartMap.empty
  |> DiskPartMap.to_seq |> List.of_seq
  |> List.sort (fun (k1, _) (k2, _) -> compare k1 k2)
  |> List.map (fun (k, l) -> (k, List.sort compare l))

let get ~disk_index ~part_index tree =
  let _, l = List.nth tree disk_index in
  List.nth l part_index

let remove_part_by_index ~disk_index ~part_index tree =
  List.mapi
    (fun i (k, l) ->
       if i = disk_index then (k, Misc_utils.list_no_nth l part_index) else (k, l))
    tree

let remove_part part tree =
  List.map
    (fun (k, l) ->
       k, List.filter (fun p -> p <> part) l
    ) tree
