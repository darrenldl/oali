open Core_kernel
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

type luks_key =
  | Key_file of string
  | Passphrase of string
[@@deriving sexp]

type luks_version =
  | LuksV1
  | LuksV2
[@@deriving sexp]

type luks =
  { enc_params : enc_params option
  ; key : luks_key
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

let mount {upper; lower} ~mount_point =
  let lower_str = lower_part_to_cmd_string lower in
  match upper with
  | PlainFS fs ->
    exec [|"mount"; lower_str; mount_point|]
  | Luks luks ->
    exec [|"cryptsetup"; "open"; "--type"; "luks"|]

let format_part {upper; lower} =
  let part_str =
    match upper with
    | PlainFS p | Luks {inner_fs = p; _} ->
      plain_part_to_string p
  in
  let command =
    match fs with
    | Fat32 ->
      [|"mkfs.fat"; "-F32 "; part_str|]
    | Ext4 ->
      [|"mkfs.ext4 "; part_str|]
  in
  Proc_utils.exec command
