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

let disk_size disk =
  let disk = String_utils.strip_prefix ~prefix:"/dev/" disk in
  let ic = open_in (Printf.sprintf "/sys/block/%s/size" disk) in
  let size_str = input_line ic in
  close_in ic; int_of_string size_str
