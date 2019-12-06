type t = (string, string) Hashtbl.t

val create : unit -> t

val to_file : string -> t -> unit

val from_file : string -> t
