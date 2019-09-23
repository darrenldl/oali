open Sexplib.Std
open Proc_utils

type fs =
  | Fat32
  | Ext4
[@@deriving sexp]

type enc_params =
  { iter_time_ms : int option
  ; key_size_bits : int option }
[@@deriving sexp]

type lower = {path : string} [@@deriving sexp]

type luks_version =
  | LuksV1
  | LuksV2
[@@deriving sexp]

type luks_state =
  | Luks_opened
  | Luks_closed
[@@deriving sexp]

type luks =
  { enc_params : enc_params
  ; primary_key : string
  ; secondary_key : string option
  ; version : luks_version
  ; inner_fs : fs
  ; mapper_name : string
  ; mutable state : luks_state }
[@@deriving sexp]

type upper =
  | Plain_FS of fs
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
  { sys_part : part (* ; swap_part : part option *)
  ; boot_part : part
  ; esp_part : part option }
[@@deriving sexp]

type layout_choice =
  | Single_disk
  | Sys_part_plus_boot_plus_maybe_EFI
  | Sys_part_plus_usb_drive
[@@deriving sexp]

let luks_version_to_int ver = match ver with LuksV1 -> 1 | LuksV2 -> 2

(* let make_lower ~disk ~part_num = {disk; part_num} *)

(* let lower_part_to_cmd_string {disk; part_num} =
 *   sprintf "/dev/%s%d" disk part_num *)

let luks_to_mapper_name_cmd_string {mapper_name; _} =
  Printf.sprintf "/dev/mapper/%s" mapper_name

let luks_open {lower; upper; _} =
  match upper with
  | Plain_FS _ ->
    failwith "LUKS expected"
  | Luks luks ->
    assert (luks.state = Luks_closed);
    let stdin, f =
      Printf.sprintf "cryptsetup open --key-file=- %s %s" lower.path
        luks.mapper_name
      |> exec_with_stdin
    in
    output_string stdin luks.primary_key;
    f ();
    luks.state <- Luks_opened

let luks_close {upper; _} =
  match upper with
  | Plain_FS _ ->
    failwith "LUKS expected"
  | Luks luks ->
    assert (luks.state = Luks_opened);
    Printf.sprintf "cryptsetup close %s" luks.mapper_name |> exec;
    luks.state <- Luks_closed

let mount_part ({lower; upper; state} as p) ~mount_point =
  assert (state = Unmounted);
  ( match upper with
    | Plain_FS _ ->
      Printf.sprintf "mount %s %s" lower.path mount_point |> exec
    | Luks luks ->
      luks_open {lower; upper; state};
      Printf.sprintf "mount %s %s"
        (luks_to_mapper_name_cmd_string luks)
        mount_point
      |> exec );
  p.state <- Mounted

let unmount_part ({lower; upper; state} as p) =
  assert (state = Mounted);
  ( match upper with
    | Plain_FS _ ->
      Printf.sprintf "umount %s" lower.path |> exec
    | Luks luks ->
      let mapper_name = luks_to_mapper_name_cmd_string luks in
      Printf.sprintf "umount %s" mapper_name |> exec;
      p.state <- Unmounted;
      luks_close {lower; upper; state} );
  p.state <- Unmounted

let format_cmd fs part =
  match fs with
  | Fat32 ->
    Printf.sprintf "mkfs.fat -F32 %s" part
  | Ext4 ->
    Printf.sprintf "mkfs.ext4 %s" part

let format_part ({upper; lower; state} as p) =
  assert (state = Unformatted);
  ( match upper with
    | Plain_FS fs ->
      format_cmd fs lower.path |> exec
    | Luks luks ->
      let iter_time_ms_opt =
        Option.map
          (fun x -> ["--iter-time"; string_of_int x])
          luks.enc_params.iter_time_ms
        |> Option.value ~default:[]
      in
      let key_size_bits_opt =
        Option.map
          (fun x -> ["--key-size"; string_of_int x])
          luks.enc_params.key_size_bits
        |> Option.value ~default:[]
      in
      (let stdin, f =
         String.concat " "
           ( [ "cryptsetup"
             ; "luksFormat"
             ; "-y"
             ; "--key-file=-"
             ; "--type"
             ; Printf.sprintf "luks%d" (luks_version_to_int luks.version) ]
             @ iter_time_ms_opt @ key_size_bits_opt @ [lower.path] )
         |> exec_with_stdin
       in
       output_string stdin luks.primary_key;
       f ());
      ( match luks.secondary_key with
        | None ->
          ()
        | Some secondary_key ->
          let tmp_path = Filename.temp_file "installer" "secondary_key" in
          let tmp_oc = open_out tmp_path in
          Fun.protect
            ~finally:(fun () -> close_out tmp_oc)
            (fun () -> output_string tmp_oc secondary_key);
          let stdin, f =
            String.concat " "
              [ "cryptsetup"
              ; "luksAddKey"
              ; "-y"
              ; "--key-file=-"
              ; lower.path
              ; tmp_path ]
            |> exec_with_stdin
          in
          output_string stdin luks.primary_key;
          f () );
      luks_open p;
      let mapper_name = luks_to_mapper_name_cmd_string luks in
      exec (format_cmd luks.inner_fs mapper_name);
      luks_close p );
  p.state <- Unmounted

let format layout =
  Option.iter format_part layout.esp_part;
  format_part layout.boot_part;
  format_part layout.sys_part

let make_luks ~enc_params ?(primary_key = Rand_utils.gen_rand_string ~len:4096)
    ?(add_secondary_key = false) ?(version = LuksV2) inner_fs ~mapper_name =
  { enc_params =
      Option.value
        ~default:{iter_time_ms = None; key_size_bits = None}
        enc_params
  ; primary_key
  ; secondary_key =
      ( if add_secondary_key then Some (Rand_utils.gen_rand_string ~len:4096)
        else None )
  ; version
  ; inner_fs
  ; mapper_name
  ; state = Luks_closed }

let make_part ~path upper =
  let lower = {path} in
  {lower; upper; state = Unformatted}

let make_layout ~esp_part ~boot_part ~sys_part = {esp_part; boot_part; sys_part}

let make_esp_part path = make_part ~path (Plain_FS Fat32)

let make_boot_part ~enc_params encrypt path =
  if encrypt then
    let primary_key =
      Misc_utils.ask_string_confirm
        ~is_valid:(fun x -> x <> "")
        "Please enter passphrase for encryption"
    in
    make_part ~path
      (Luks
         (make_luks ~enc_params ~primary_key ~add_secondary_key:true
            ~version:LuksV1 Ext4 ~mapper_name:Config.boot_mapper_name))
  else make_part ~path (Plain_FS Ext4)

let make_sys_part ~enc_params encrypt path =
  if encrypt then
    make_part ~path
      (Luks (make_luks Ext4 ~enc_params ~mapper_name:Config.root_mapper_name))
  else make_part ~path (Plain_FS Ext4)

let mount_esp_part layout =
  mount_part (Option.get layout.esp_part) ~mount_point:Config.esp_mount_point

let mount_boot_part layout =
  mount_part layout.boot_part ~mount_point:Config.boot_mount_point

let mount_sys_part layout =
  mount_part layout.sys_part ~mount_point:Config.sys_mount_point

let unmount_esp_part layout = Option.iter unmount_part layout.esp_part

let unmount_boot_part layout = unmount_part layout.boot_part

let unmount_sys_part layout = unmount_part layout.sys_part

let unmount layout =
  unmount_esp_part layout; unmount_boot_part layout; unmount_sys_part layout
