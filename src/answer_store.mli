type t = (string, string) Hashtbl.t

val create : unit -> t

val write : task_name:string -> t -> unit

val load : task_name:string -> t
