module DiskPartMap = Map.Make(
  struct
    type t = string
    let compare = compare
  end
  )

let list_parts () =
  let dir = "/dev/disk/by-partuuid/" in
  let uuids = Sys.readdir dir |> Array.to_list in
  uuids
  |> List.map (fun s -> dir ^ s)
  |> List.map Unix.readlink
  |> List.map (String_utils.tail 6)
  |> List.filter (fun s -> String.sub s 0 2 <> "dm")
  |> List.map (fun s -> "/dev/" ^ s)

let part_to_disk s =
  String_utils.strip_tail_num s

let list_disks () =
  let parts = list_parts () in
  parts
  |> List.map part_to_disk
  |> List.sort_uniq compare

let group_parts_by_disks_map parts =
  parts
  |> List.map (fun part -> part_to_disk part, part)
  |> List.fold_left (fun tbl (disk, part) ->
      match DiskPartMap.find_opt disk tbl with
      | None -> DiskPartMap.add disk [part] tbl
      | Some l -> DiskPartMap.add disk (part :: l) tbl
    ) DiskPartMap.empty

let group_parts_by_disks parts =
  group_parts_by_disks_map parts
  |> DiskPartMap.to_seq
  |> List.of_seq
  |> List.sort (fun (k1, _) (k2, _) -> compare k1 k2)
  |> List.map (fun (k, l) ->
      k, List.sort compare l
    )
