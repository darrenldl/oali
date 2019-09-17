type t = (string * string list) list

val of_parts : string list -> t

val get : disk_index:int -> part_index:int -> t -> string

val remove_part_by_index : disk_index:int -> part_index:int -> t -> t

val remove_part : string -> t -> t
