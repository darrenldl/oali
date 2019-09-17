open Sexplib.Std

type task = Task_config.t -> Task_config.t

type progress = {finished : string list} [@@deriving sexp]

type t =
  { mutable config : Task_config.t
  ; to_run : (string * task) Queue.t
  ; failed : (string * task) Queue.t
  ; finished : (string * task) Queue.t }

let make config =
  { config
  ; to_run = Queue.create ()
  ; failed = Queue.create ()
  ; finished = Queue.create () }

let to_progress task_book =
  let acc = ref [] in
  Queue.iter (fun x -> acc := x :: !acc) task_book.finished;
  List.rev !acc

let register task_book ~name task = Queue.push (name, task) task_book.to_run

let run task_book =
  let rec aux task_book (retry : (string * task) option) =
    let to_run =
      match retry with
      | Some x ->
        Some x
      | None ->
        Queue.take_opt task_book.to_run
    in
    match to_run with
    | None ->
      ()
    | Some (name, task) ->
      Proc_utils.exec_no_capture "clear";
      print_endline name;
      for _ = 0 to String.length name - 1 do
        print_string "="
      done;
      print_newline ();
      print_newline ();
      let succeeded, new_config =
        try
          let config = task task_book.config in
          print_newline (); (true, config)
        with
        | Proc_utils.Exec_fail r ->
          print_endline (Proc_utils.report_failure r);
          (false, task_book.config)
        | Failure msg ->
          Printf.printf "Failure : %s\n" msg;
          (false, task_book.config)
        | Sys_error msg ->
          Printf.printf "Sys_error : %s\n" msg;
          (false, task_book.config)
        | _ ->
          print_endline "Unknown failure";
          (false, task_book.config)
      in
      if not succeeded then
        let retry =
          Misc_utils.ask_yn "Do you want to retry task unit?" = Yes
        in
        if retry then aux task_book (Some (name, task))
        else Queue.push (name, task) task_book.failed
      else (
        task_book.config <- new_config;
        Queue.push (name, task) task_book.finished;
        aux task_book None )
  in
  aux task_book None
