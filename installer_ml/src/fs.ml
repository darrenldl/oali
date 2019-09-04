let format_part fs part =
  let part_str = Partition.to_string part in
  let command =
    match fs with
    | Fat32 -> [|"mkfs.fat"; "-F32 "; part_str|]
    | Ext4 -> [|"mkfs.ext4 "; part_str|]
  in
  Process_utils.exec ("", command)
