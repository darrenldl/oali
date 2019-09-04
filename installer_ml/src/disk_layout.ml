type partition =
  { disk : string
  ; part_num : int }

type disk_layout =
  { sys_part : string
  ; swap_part : string option
  ; boot_part : string
  ; efi_part : string option }
