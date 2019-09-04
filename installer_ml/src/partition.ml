open Core_kernel

type t =
  | Device of { disk : string
           ; part_num : int }
  | Luks of { mapped_name : string }
[@@deriving sexp]

let make_for_device ~disk ~part_num =
  Device { disk; part_num }

let make_for_luks ~mapped_name =
  Luks { mapped_name }

let same_disk p1 p2 =
  match p1, p2 with
  | Device { disk = d1; _ }, Device { disk = d2; _} -> d1 = d2
  | _ -> false

let to_string p = match p with
  | Device { disk; part_num } ->
    Printf.sprintf "/dev/%s%d" disk part_num
  | Luks { mapped_name }->
    Printf.sprintf "/dev/mapper/%s" mapped_name
