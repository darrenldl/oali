let list_disk_block_devs () =
  let dir = "/dev/disk/by-path/" in
  let paths = Sys.readdir dir |> Array.to_list in
  paths
  |> List.map (fun s -> dir ^ s)
  |> List.map Unix.readlink
  |> List.map (String_utils.tail 6)
  |> List.filter (fun s -> String.sub s 0 2 <> "dm")
  |> List.filter (fun s -> String.sub s 0 2 <> "sr")
  |> List.map (fun s -> "/dev/" ^ s)

let list_parts () =
  list_disk_block_devs ()
  |> List.filter (fun s -> match String_utils.get_tail_num s with
      | Some _ -> true
      | None -> false)

let part_to_disk s = String_utils.strip_tail_num s

let list_disks () =
  list_disk_block_devs ()
  |> List.filter (fun s -> match String_utils.get_tail_num s with
      | Some _ -> false
      | None -> true)

let disk_size disk =
  let res = Proc_utils.exec_ret (Printf.sprintf "blockdev --getsize64 %s" disk) in
  let size_str = List.hd res.stdout in
  int_of_string size_str
