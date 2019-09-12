type t =
  { disk_layout : Disk_layout.t option
  ; editor : string option }

let create () = {disk_layout = None; editor = None}
