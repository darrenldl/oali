let part_list () =
  let dir = "/dev/disk/by-uuid/" in
  let uuids = Sys.readdir dir |> Array.to_list in
  uuids
  |> List.map (fun s -> dir ^ s)
  |> List.map Unix.readlink
  |> List.map (String_utils.tail 6)
  |> fun x -> List.combine x uuids
  |> List.filter (fun (s, _) -> String.sub s 0 2 <> "dm")
  |> List.map (fun (x, y) -> "/dev/" ^ x, y)

let disk_list () =
  let parts = part_list () in
  parts
  |> List.map (fun (x, _) -> x)
  |> List.map String_utils.strip_tail_num
  |> List.sort_uniq compare

