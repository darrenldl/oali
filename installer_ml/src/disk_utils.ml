let list_parts () =
  let dir = "/dev/disk/by-partuuid/" in
  let uuids = Sys.readdir dir |> Array.to_list in
  uuids
  |> List.map (fun s -> dir ^ s)
  |> List.map Unix.readlink
  |> List.map (String_utils.tail 6)
  |> List.filter (fun s -> String.sub s 0 2 <> "dm")
  |> List.map (fun s -> "/dev/" ^ s)

let part_to_disk s = String_utils.strip_tail_num s

let list_disks () =
  let parts = list_parts () in
  parts |> List.map part_to_disk |> List.sort_uniq compare
