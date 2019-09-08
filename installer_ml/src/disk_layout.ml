open Sexplib.Std
open Proc_utils

type fs =
  | Fat32
  | Ext4
[@@deriving sexp]

type enc_params =
  { iter_time_ms : int
  ; key_size : int }
[@@deriving sexp]

type lower =
  { disk : string
  ; part_num : int }
[@@deriving sexp]

type plain_fs = {fs : fs} [@@deriving sexp]

type luks_version =
  | LuksV1
  | LuksV2
[@@deriving sexp]

type luks_state =
  | LuksOpened
  | LuksClosed
[@@deriving sexp]

type luks =
  { enc_params : enc_params option
  ; key : string
  ; version : luks_version
  ; inner_fs : plain_fs
  ; mapper_name : string
  ; mutable state : luks_state }
[@@deriving sexp]

type upper =
  | PlainFS of plain_fs
  | Luks of luks
[@@deriving sexp]

type state =
  | Unformatted
  | Mounted
  | Unmounted
[@@deriving sexp]

type part =
  { lower : lower
  ; upper : upper
  ; mutable state : state }
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

let luks_open {lower; upper; _} =
  let lower_str = lower_part_to_cmd_string lower in
  match upper with
  | PlainFS _ ->
    failwith "LUKS expected"
  | Luks luks ->
    assert (luks.state = LuksClosed);
    let stdin, f =
      exec_with_stdin "cryptsetup"
        [|"open"; "--key-file=-"; lower_str; luks.mapper_name|]
    in
    output_string stdin luks.key;
    f ()

let luks_close {upper; _} =
  match upper with
  | PlainFS _ ->
    failwith "LUKS expected"
  | Luks luks ->
    assert (luks.state = LuksOpened);
    exec "cryptsetup" [|"close"; luks.mapper_name|]

let mount_part ({lower; upper; state}) ~mount_point =
  assert (state = Unmounted);
  let lower_str = lower_part_to_cmd_string lower in
  match upper with
  | PlainFS _ ->
    exec "mount" [|lower_str; mount_point|]
  | Luks luks ->
    luks_open {lower; upper; state};
    exec "mount" [|luks_to_mapper_name_cmd_string luks; mount_point|]

let unmount_part ({lower; upper; state} as p) =
  assert (state = Mounted);
  let lower_str = lower_part_to_cmd_string lower in
  match upper with
  | PlainFS _ ->
    exec "umount" [|lower_str|]
  | Luks luks -> (
      let mapper_name = luks_to_mapper_name_cmd_string luks in
      exec "umount" [|mapper_name|];
      p.state <- Unmounted;
      luks_close {lower; upper; state} )

let format_cmd fs part =
  match fs with
  | Fat32 ->
    ("mkfs.fat", [|"-F32"; part|])
  | Ext4 ->
    ("mkfs.ext4", [|part|])

let format_part ({upper; lower; state} as p) =
  assert (state = Unformatted);
  let lower_str = lower_part_to_cmd_string lower in
  match upper with
  | PlainFS {fs} ->
    let prog, args = format_cmd fs lower_str in
    exec prog args;
    p.state <- Unmounted;
  | Luks luks ->
      let enc_params = Option.get luks.enc_params in
      let stdin, f =
        exec_with_stdin "cryptsetup"
          [| "luksFormat"
           ; "-y"
           ; "--key-file=-"
           ; "--iter-time"
           ; string_of_int enc_params.iter_time_ms
           ; "--key-size"
           ; string_of_int enc_params.key_size |]
      in
      output_string stdin luks.key;
      f ();
      let mapper_name = luks_to_mapper_name_cmd_string luks in
      let prog, args = format_cmd luks.inner_fs.fs mapper_name in
      exec prog args
