type task = Task_config.t -> unit

type t = {
  config : Task_config.t;
  to_run : (string * task) Queue.t;
  finished : (string * task) Queue.t;
}

let make config =
  { config;
    to_run = Queue.create ()
  ; finished = Queue.create ()}

let register task_book ~name task =
  Queue.push (name, task) task_book.to_run

let run task_book =
  let rec aux task_book (retry : (string * task) option) =
    let to_run = match retry with
      | Some x -> Some x
      | None -> Queue.take_opt task_book.to_run
    in
    match to_run with
    | None -> ()
    | Some (name, task) ->
      let succeeded =
        begin
          try
            task task_book.config;
            true
          with Proc_utils.Exec_fail r ->
            print_endline (Proc_utils.report_failure r);
            false
        end in
      if not succeeded then
        (* TODO ask if retry *)

        let retry = false in
        if retry then
          aux task_book (Some (name, task))
        else (
          ()
        )
      else (
        Queue.push (name, task) task_book.finished;
        aux task_book None
      )
  in
  aux task_book None
