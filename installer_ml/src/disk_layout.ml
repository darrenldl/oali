open Core_kernel

type fs =
  Fat32 | Ext4 [@@deriving sexp]

type enc_params =
  { iter_time : int
  } [@@deriving sexp]

type plain_part = { disk : string
                  ; part_num : int } [@@deriving sexp]

type luks_part = { raw : plain_part
                 ; enc_params : enc_params
                 ; mapped_name : string
                 ; fs : fs } [@@deriving sexp]

type part =
  | Plain of plain_part * fs
  | Luks of luks_part
[@@deriving sexp]

type t =
  { sys_part : part
  ; swap_part : part option
  ; boot_part : part
  ; efi_part : plain_part option
  } [@@deriving sexp]

let make_plain_part ~disk ~part_num = { disk; part_num }

let make_luks_part ~raw_disk ~raw_part_num ~enc_params ~mapped_name =
  { raw = make_plain_part ~disk:raw_disk ~part_num:raw_part_num
  ; enc_params
  ; mapped_name
  ; fs }

let plain_part_to_string { disk; part_num } =
    Printf.sprintf "/dev/%s%d" disk part_num

let part_to_string_for_cmd p = match p with
  | Plain p ->
    plain_part_to_string p
  | Luks { mapped_name; _ }->
    Printf.sprintf "/dev/mapper/%s" mapped_name

let format_part p =
  let part_str =
    match p with
    | Plain p | Luks { raw = p; _ } ->
      plain_part_to_string p
  in
  let command =
    match fs with
    | Fat32 -> [|"mkfs.fat"; "-F32 "; part_str|]
    | Ext4 -> [|"mkfs.ext4 "; part_str|]
  in
  Proc_utils.exec ("", command)
