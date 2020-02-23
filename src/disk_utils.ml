let sync () = Proc_utils.exec "sync"

let list_disk_block_devs () =
  Unix.sleepf 0.2;
  sync ();
  Unix.sleepf 0.2;
  let dir = "/dev/disk/by-path/" in
  let paths = Sys.readdir dir |> Array.to_list in
  let dsts =
    paths
    |> List.map (fun s -> dir ^ s)
    |> List.map Unix.readlink
    |> List.map (String_utils.tail_w_pos ~pos:6)
  in
  List.combine paths dsts
  |> List.filter (fun (_path, dst) ->
      Core_kernel.String.substr_index dst ~pattern:"dm" <> Some 0)
  |> List.filter (fun (_path, dst) ->
      Core_kernel.String.substr_index dst ~pattern:"sr" <> Some 0)
  |> List.map (fun (path, dst) -> (path, "/dev/" ^ dst))
  |> List.sort_uniq compare

let list_parts () =
  list_disk_block_devs ()
  |> List.filter (fun (path, _dst) ->
      let last_part = List.hd (List.rev (String.split_on_char '-' path)) in
      match Core_kernel.String.substr_index last_part ~pattern:"part" with
      | Some _ -> true
      | None -> false)
  |> List.map (fun (_, dst) -> dst)
  |> List.sort_uniq compare

let disk_of_part part =
  let devs = list_disk_block_devs () in
  let part_path, _ = List.find (fun (_path, dst) -> dst = part) devs in
  let disk_path =
    part_path
    |> String.split_on_char '-'
    |> List.rev
    |> List.tl
    |> List.rev
    |> String.concat "-"
  in
  let _, disk_name = List.find (fun (path, _dst) -> path = disk_path) devs in
  disk_name

let parts_of_disk disk =
  let len = String.length disk in
  list_parts ()
  |> List.filter (fun part -> Core_kernel.String.prefix part len = disk)

let list_disks () =
  list_disk_block_devs ()
  |> List.filter (fun (path, _dst) ->
      let last_part = List.hd (List.rev (String.split_on_char '-' path)) in
      match Core_kernel.String.substr_index last_part ~pattern:"part" with
      | Some _ -> false
      | None -> true)
  |> List.map (fun (_, dst) -> dst)
  |> List.sort_uniq compare

let disk_size_bytes disk =
  let res =
    Proc_utils.exec_ret (Printf.sprintf "blockdev --getsize64 %s" disk)
  in
  let size_str = List.hd res.stdout in
  int_of_string size_str

let disk_size_KiB disk : float = float_of_int (disk_size_bytes disk) /. 1024.0

let disk_size_MiB disk : float = disk_size_KiB disk /. 1024.0

let uuid_of_dev dev =
  let dir = "/dev/disk/by-uuid" in
  let uuids = Sys.readdir dir |> Array.to_list in
  let devs =
    uuids
    |> List.map (Filename.concat dir)
    |> List.map Unix.readlink
    |> List.map (String_utils.tail_w_pos ~pos:6)
  in
  List.combine devs uuids
  |> List.filter (fun (s, _) -> s = Filename.basename dev)
  |> List.hd
  |> fun (_, uuid) -> uuid

let gpt_sgdisk_back_up ~disk ~backup_location ~backup_file_prefix =
  Printf.sprintf "sgdisk --backup=%s %s"
    (Misc_utils.concat_file_names
       [ backup_location; backup_file_prefix ^ Config.gpt_sgdisk_backup_suffix ])
    disk
  |> Proc_utils.exec_no_capture

let mbr_sfdisk_back_up ~disk ~backup_location ~backup_file_prefix =
  Printf.sprintf "sfdisk -d %s > %s" disk
    (Misc_utils.concat_file_names
       [ backup_location; backup_file_prefix ^ Config.mbr_sfdisk_backup_suffix ])
  |> Proc_utils.exec_no_capture

let part_table_back_up ~is_efi_mode ~disk ~backup_location ~backup_file_prefix =
  if is_efi_mode then
    gpt_sgdisk_back_up ~disk ~backup_location ~backup_file_prefix
  else mbr_sfdisk_back_up ~disk ~backup_location ~backup_file_prefix
