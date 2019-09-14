let part_list () =
  let dir = "/dev/disk/by-uuid/" in
  let uuids = Sys.readdir dir in
  uuids |> Array.to_list
  |> List.map (fun s -> dir ^ s)
  |> List.map Unix.readlink
  |> List.map (String_utils.tail 6)
  |> List.filter (fun s -> String.sub s 0 2 <> "dm")
  |> List.map (fun s -> "/dev/" ^ s)
