let part_lists () =
  let uuids = Sys.readdir "/dev/disk/by-uuid/" in
  uuids
  |> Array.map Unix.readlink
  |> Array.map (String_utils.tail 5)
  |> Array.to_list
