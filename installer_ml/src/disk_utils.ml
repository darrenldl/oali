module DiskPartMap = Map.Make(
    struct
      type t = string
      let compare = compare
end
)

let list_parts () =
  let dir = "/dev/disk/by-uuid/" in
  let uuids = Sys.readdir dir |> Array.to_list in
  uuids
  |> List.map (fun s -> dir ^ s)
  |> List.map Unix.readlink
  |> List.map (String_utils.tail 6)
  |> fun x -> List.combine x uuids
  |> List.filter (fun (s, _) -> String.sub s 0 2 <> "dm")
  |> List.map (fun (x, y) -> "/dev/" ^ x, y)

let part_to_disk s =
  String_utils.strip_tail_num s

let list_disks () =
  let parts = list_parts () in
  parts
  |> List.map (fun (x, _) -> x)
  |> List.map part_to_disk
  |> List.sort_uniq compare

let group_parts_by_disks parts =
  parts
  |> List.map (fun (part, uuid) -> part_to_disk part, part, uuid)
  |> List.fold_left (fun tbl (disk, part, uuid) ->
      match DiskPartMap.find_opt disk tbl with
      | None -> DiskPartMap.add disk [(part, uuid)] tbl
      | Some l -> DiskPartMap.add disk ((part, uuid) :: l) tbl
    ) DiskPartMap.empty
