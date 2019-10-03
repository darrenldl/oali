open Sexplib.Std

type task = Task_config.t -> Task_config.t

type task_result =
  | Not_run
  | Okay
  | Failed

type stats =
  { result : task_result
  ; exec_count : int }

type task_record =
  { name : string
  ; task : task
  ; stats : stats }

type progress = {finished : string list} [@@deriving sexp]

type task_fail_choice =
  | Retry
  | Skip
  | End_install

type t =
  { mutable config : Task_config.t
  ; mutable tasks : task_record list }

let make config = {config; tasks = []}

let register task_book ~name task =
  task_book.tasks <-
    {name; task; stats = {result = Not_run; exec_count = 0}} :: task_book.tasks

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
      Proc_utils.clear ();
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
          (* | _ ->
           *   print_endline "Unknown failure";
           *   (false, task_book.config) *)
      in
      if not succeeded then
        let choices =
          [("retry", Retry); ("skip", Skip); ("end install", End_install)]
        in
        let choice_index =
          Misc_utils.pick_choice ~confirm:true
            (List.map (fun (x, _) -> x) choices)
        in
        let choice = List.nth choices choice_index |> fun (_, x) -> x in
        match choice with
        | Retry ->
          aux task_book (Some (name, task))
        | Skip ->
          Queue.push (name, task) task_book.failed;
          aux task_book None
        | End_install ->
          Queue.push (name, task) task_book.failed
      else (
        task_book.config <- new_config;
        Queue.push (name, task) task_book.finished;
        aux task_book None )
  in
  aux task_book None
