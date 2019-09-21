type t =
  { disk_layout : Disk_layout.t option
  ; disk_layout_choice : Disk_layout.layout_choice option
  ; is_efi_mode : bool option
  ; encrypt : bool option
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
  ; encrypt = None
  ; editor = None
  ; hostname = None
  ; use_saltstack = None
  ; user_name = None
  ; do_unmount = None
  ; do_shutdown = None }
