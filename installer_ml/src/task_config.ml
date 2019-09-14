type t =
  { disk_layout : Disk_layout.t option
  ; disk_layout_choice : Disk_layout.layout_choice option
  ; editor : string option }

let create () = {disk_layout = None; disk_layout_choice = None; editor = None}
