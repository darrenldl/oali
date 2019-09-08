type task = Config.t -> unit

type task_book = {
  config : Config.t;
  to_run : (string * task) Queue.t;
  finished : (string * task) Queue.t;
}

let register task_book ~name task =
  Queue.push (name, task) task_book

let run task_book =
  let rec aux task_book =
    match Queue.take_opt task_book.to_run with
    | None -> ()
    | Some (name, task) ->
      task task_book.config;
      Queue.push (name, task) task_book.finished;
      aux task_book
  in
  aux task_book
