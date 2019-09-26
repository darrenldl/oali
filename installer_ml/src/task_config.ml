type t =
  { disk_layout : Disk_layout.t option
  ; disk_layout_choice : Disk_layout.layout_choice option
  ; is_efi_mode : bool option
  ; add_hardened : bool option
  ; hardened_as_default : bool option
  ; encrypt : bool option
  ; boot_part_enc_params : Disk_layout.enc_params option
  ; sys_part_enc_params : Disk_layout.enc_params option
  ; editor : string option
  ; hostname : string option
  ; use_saltstack : bool option
  ; user_name : string option
  ; do_unmount : bool option
  ; do_shutdown : bool option }

let create () =
  { disk_layout = None
  ; disk_layout_choice = None
  ; is_efi_mode = None
  ; add_hardened = None
  ; hardened_as_default = None
  ; encrypt = None
  ; boot_part_enc_params = None
  ; sys_part_enc_params = None
  ; editor = None
  ; hostname = None
  ; use_saltstack = None
  ; user_name = None
  ; do_unmount = None
  ; do_shutdown = None }
