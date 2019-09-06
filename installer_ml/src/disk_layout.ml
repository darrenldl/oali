open Sexplib.Std
open Proc_utils

type fs =
  | Fat32
  | Ext4
[@@deriving sexp]

type enc_params = {iter_time : int} [@@deriving sexp]

type lower =
  { disk : string
  ; part_num : int }
[@@deriving sexp]

type plain_fs = {fs : fs} [@@deriving sexp]

type luks_version =
  | LuksV1
  | LuksV2
[@@deriving sexp]

type luks =
  { enc_params : enc_params option
  ; key : string
  ; version : luks_version
  ; inner_fs : plain_fs
  ; mapper_name : string }
[@@deriving sexp]

type upper =
  | PlainFS of plain_fs
  | Luks of luks
[@@deriving sexp]

type part =
  { lower : lower
  ; upper : upper }
[@@deriving sexp]

type t =
  { sys_part : part
  ; swap_part : part option
  ; boot_part : part
  ; efi_part : part option }
[@@deriving sexp]

let make_lower ~disk ~part_num = {disk; part_num}

let lower_part_to_cmd_string {disk; part_num} =
  Printf.sprintf "/dev/%s%d" disk part_num

let luks_to_mapper_name_cmd_string {mapper_name; _} =
  Printf.sprintf "/dev/mapper/%s" mapper_name

let luks_open {lower; upper} =
  let lower_str = lower_part_to_cmd_string lower in
  match upper with
  | PlainFS _ ->
    failwith "LUKS expected"
  | Luks luks ->
    let stdin, f =
      exec_with_stdin
        [|"cryptsetup"; "open"; "--key-file=-"; lower_str; luks.mapper_name|]
    in
    let%lwt () = Lwt_io.write stdin luks.key in
    let%lwt () = Lwt_io.close stdin in
    let%lwt res = f () in
    Stdlib.Result.map_error
      (fun _ -> Printf.sprintf "Failed to open LUKS device %s" lower_str)
      res
    |> Lwt.return

let luks_close {lower; upper} =
  let lower_str = lower_part_to_cmd_string lower in
  match upper with
  | PlainFS _ ->
    failwith "LUKS expected"
  | Luks luks ->
    let%lwt res = exec [|"cryptsetup"; "close"; luks.mapper_name|] in
    Stdlib.Result.map_error
      (fun _ -> Printf.sprintf "Failed to close LUKS device %s" lower_str)
      res
    |> Lwt.return

let mount_part {lower; upper} ~mount_point =
  let lower_str = lower_part_to_cmd_string lower in
  match upper with
  | PlainFS _ ->
    let%lwt res = exec [|"mount"; lower_str; mount_point|] in
    Stdlib.Result.map_error
      (fun _ -> Printf.sprintf "Failed to mount %s" lower_str)
      res
    |> Lwt.return
  | Luks luks -> (
      let%lwt res = luks_open {lower; upper} in
      match res with
      | Error e ->
        Lwt.return_error e
      | Ok _ ->
        let%lwt res =
          exec [|"mount"; luks_to_mapper_name_cmd_string luks; mount_point|]
        in
        Stdlib.Result.map_error
          (fun _ -> "Failed to mount mapper device")
          res
        |> Lwt.return )

let unmount_part {lower; upper} =
  let lower_str = lower_part_to_cmd_string lower in
  match upper with
  | PlainFS _ ->
    let%lwt res = exec [|"umount"; lower_str|] in
    Stdlib.Result.map_error
      (fun _ -> Printf.sprintf "Failed to unmount %s" lower_str)
      res
    |> Lwt.return
  | Luks luks -> (
      let mapper_name = luks_to_mapper_name_cmd_string luks in
      let%lwt res = exec [|"umount"; mapper_name|] in
      match res with
      | Error _ ->
        Lwt.return_error (Printf.sprintf "Failed to unmount %s" mapper_name)
      | Ok _ ->
        let%lwt res = exec [|"cryptsetup"; "close"; luks.mapper_name|] in
        Stdlib.Result.map_error
          (fun _ ->
             Printf.sprintf "Failed to close LUKS device %s" lower_str)
          res
        |> Lwt.return )

let format_cmd fs part =
  match fs with
  | Fat32 ->
    [|"mkfs.fat"; "-F32"; part|]
  | Ext4 ->
    [|"mkfs.ext4"; part|]

(* let format_part {upper; lower} =
 *   let lower_str = lower_part_to_cmd_string lower in
 *   match upper with
 *   | PlainFS {fs} ->
 *     let%lwt res = exec (format_cmd fs lower_str) in
 *     Stdlib.Result.map_error (fun _ -> Printf.sprintf "Failed to format %s" lower_str)
 *       res
 *     |> Lwt.return
 *   | Luks luks ->
 *     let%lwt res = exec *)

(* let format_part {upper; lower} =
 *   let part_str =
 *     match upper with
 *     | PlainFS p | Luks {inner_fs = p; _} ->
 *       plain_part_to_string p
 *   in
 *   let command =
 *     match fs with
 *     | Fat32 ->
 *       [|"mkfs.fat"; "-F32 "; part_str|]
 *     | Ext4 ->
 *       [|"mkfs.ext4 "; part_str|]
 *   in
 *   Proc_utils.exec command *)
