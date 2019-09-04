open Core_kernel

let make_for_device ~disk ~part_num =
  Device { disk; part_num }

let make_for_luks ~mapped_name =
  Luks { mapped_name }

let same_disk p1 p2 =
  match p1, p2 with
  | Device { disk = d1; _ }, Device { disk = d2; _} -> d1 = d2
  | _ -> false

