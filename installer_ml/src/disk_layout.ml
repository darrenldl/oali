open Core_kernel

type disk_layout =
  { sys_part : Partition.t
  ; swap_part : Partition.t option
  ; boot_part : Partition.t
  ; efi_part : Partition.t option
  } [@@deriving sexp]
