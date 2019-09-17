type t =
  { disk_layout : Disk_layout.t option
  ; disk_layout_choice : Disk_layout.layout_choice option
  ; is_efi_mode : bool option
  ; encrypted : bool option
  ; editor : string option
  ; hostname : string option }

let create () =
  { disk_layout = None
  ; disk_layout_choice = None
  ; is_efi_mode = None
  ; encrypted = None
  ; editor = None
  ; hostname = None }
