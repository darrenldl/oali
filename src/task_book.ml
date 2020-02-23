type task = Answer_store.t -> Task_config.t -> Task_config.t

exception End_install

type installer_state =
  | Fresh
  | Repeat
  | Terminating

type installation_action =
  | Run_everything
  | Run_skip_to_task
  | Gen_doc
  | Terminate

type task_result =
  | Not_run
  | Okay
  | Failed
  | Skipped

type stats = {
  mutable result : task_result;
  mutable exec_count : int;
}

type task_record = {
  name : string;
  doc : string;
  task : task;
  stats : stats;
}

type progress = { finished : string list } [@@deriving sexp]

type task_fail_choice =
  | Retry
  | Skip
  | End_install

type t = {
  mutable config : Task_config.t;
  mutable task_queue : task_record list;
  mutable tasks_to_run : task_record array option;
  mutable cur_task : int option;
}

let task_result_to_string res =
  match res with
  | Not_run -> "Not run"
  | Okay -> "Finished successfully"
  | Failed -> "Failed"
  | Skipped -> "Skipped"

let make config =
  { config; task_queue = []; tasks_to_run = None; cur_task = None }

let register task_book ~name ~doc task =
  task_book.task_queue <-
    { name; doc; task; stats = { result = Not_run; exec_count = 0 } }
    :: task_book.task_queue

let finalize task_book =
  assert (task_book.tasks_to_run = None);
  task_book.tasks_to_run <- Some (Array.of_list (List.rev task_book.task_queue))

let print_task_list task_book =
  let tasks_to_run = Option.get task_book.tasks_to_run in
  print_endline "Task list";
  Array.iteri
    (fun i task_record -> Printf.printf "%5d    %s\n" i task_record.name)
    tasks_to_run

let pick_task task_book =
  let tasks_to_run = Option.get task_book.tasks_to_run in
  let choices =
    tasks_to_run
    |> Array.to_list
    |> List.map (fun record ->
        Printf.sprintf "%s    %s" record.name
          (task_result_to_string record.stats.result))
  in
  Misc_utils.pick_choice_num ~header:"Tasks" choices

let rec run_single_task task_book task_index task_record : unit =
  let task_name = task_record.name in
  let task = task_record.task in
  let answer_store = Answer_store.load ~task_name in
  Proc_utils.clear ();
  let title = Printf.sprintf "%2d. %s" task_index task_name in
  print_endline title;
  for _ = 0 to String.length title - 1 do
    print_string "="
  done;
  print_newline ();
  print_newline ();
  let succeeded, new_config =
    try
      let config = task answer_store task_book.config in
      print_newline ();
      Answer_store.write ~task_name answer_store;
      (true, config)
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
    | Unix.Unix_error (err, s1, s2) ->
      Printf.printf "Unix.Unix_error : %s, %s, %s\n" (Unix.error_message err)
        s1 s2;
      (false, task_book.config)
    | FileUtilCP.CpError msg ->
      Printf.printf "FileUtilCP.CpError : %s\n" msg;
      (false, task_book.config)
  in
  if not succeeded then (
    let choices =
      [ ("Retry", Retry); ("Skip", Skip); ("End install", End_install) ]
    in
    let choice = Misc_utils.pick_choice_kv ~confirm:true choices in
    match choice with
    | Retry -> run_single_task task_book task_index task_record
    | Skip -> task_record.stats.result <- Skipped
    | End_install ->
      task_record.stats.result <- Failed;
      raise End_install )
  else task_book.config <- new_config

let pick_installer_action () =
  let choices =
    [
      ("Run all tasks", Run_everything);
      ("Run, skip to task", Run_skip_to_task);
      ("Generate markdown doc", Gen_doc);
      ("Terminate", Terminate);
    ]
  in
  Misc_utils.pick_choice_kv ~header:"Actions" choices

let pick_tasks_to_run action task_book : (int * task_record array) option =
  let tasks = Option.get task_book.tasks_to_run in
  let task_count = Array.length tasks in
  match action with
  | Run_everything -> Some (0, tasks)
  | Run_skip_to_task ->
    let skip_to = pick_task task_book in
    Some (skip_to, Array.sub tasks skip_to (task_count - skip_to))
  | Gen_doc -> None
  | Terminate -> None

let gen_doc_md task_book =
  let oc = open_out Config.doc_md_name in
  Fun.protect
    ~finally:(fun () -> close_out oc)
    (fun () ->
       Printf.fprintf oc "# Oali workflow details\n";
       Printf.fprintf oc "\n";
       Printf.fprintf oc
         "This doc is generated via Oali. Please do not edit directly.\n";
       Printf.fprintf oc "\n";
       task_book.task_queue
       |> List.rev
       |> List.iteri (fun i task_record ->
           Printf.fprintf oc "## %d. %s\n" i task_record.name;
           Printf.fprintf oc "\n";
           Printf.fprintf oc "%s\n" task_record.doc;
           Printf.fprintf oc "\n"))

let run task_book =
  let rec aux task_book =
    match pick_installer_action () with
    | Gen_doc -> gen_doc_md task_book
    | Terminate -> ()
    | action -> (
        let first_index, tasks =
          Option.get (pick_tasks_to_run action task_book)
        in
        Sys.set_signal Sys.sigint
          (Sys.Signal_handle
             (fun _ ->
                print_endline "Interrupted received";
                print_endline "Terminating installation";
                raise End_install));
        try
          Array.iteri
            (fun i task_record ->
               let cur_task_index = first_index + i in
               task_book.cur_task <- Some cur_task_index;
               run_single_task task_book cur_task_index task_record)
            tasks;
          print_endline "All tasks were executed successfully"
        with End_install ->
          print_endline
            "Installation ended as requested, returning to main menu";
          aux task_book )
  in
  finalize task_book;
  Proc_utils.clear ();
  print_endline "Welcome to oali - OCaml Arch Linux Installer";
  aux task_book
