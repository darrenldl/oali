open Proc_utils

type fs =
  [ `Fat32
  | `Ext4
  ]

(* type inner =
 *   | Fs of fs
 *   | Lvm of lvm *)

module Luks_info = struct
  type enc_params = {
    iter_time_ms : int option;
    key_size_bits : int option;
  }

  type luks_version =
    [ `LuksV1
    | `LuksV2
    ]

  type luks_state =
    [ `Luks_opened
    | `Luks_closed
    ]

  type t = {
    enc_params : enc_params;
    primary_key : string;
    secondary_key : string option;
    version : luks_version;
    mapper_name : string;
    mutable state : luks_state;
  }
end

(* type upper =
 *   | Plain_Fs of fs
 *   | Luks of luks *)

type state =
  [ `Unformatted
  | `Mounted
  | `Unmounted
  ]

(* type simple_part = {
 *   lower : lower;
 *   upper : upper;
 *   mutable state : state;
 * } *)

(* type lvm_lv = {
 *   lv_name : string;
 *   luks : luks;
 * } *)

(* type part =
 *   | Simple of simple_part
 *   | Lvm of lvm_lv *)

type upper = {
  mount_point : string;
  fs : fs;
}

type lvm_lv = {
  lv_name : string;
  vg_name : string;
}

type mid = lvm_lv option

type lower =
  | Clear of { path : string }
  | Luks of {
      luks : Luks_info.t;
      path : string;
    }

type t = {
  upper : upper;
  mid : mid;
  lower : lower;
  mutable state : state;
}

let luks_version_to_int ver = match ver with `LuksV1 -> 1 | `LuksV2 -> 2

let path_to_lower_for_mid (t : t) : string =
  match t.lower with
  | Clear { path } -> path
  | Luks { luks; _ } -> Printf.sprintf "/dev/mapper/%s" luks.mapper_name

let path_to_mid_for_upper (t : t) : string =
  match t.mid with
  | None -> path_to_lower_for_mid t
  | Some x -> Printf.sprintf "/dev/%s/%s" x.vg_name x.lv_name

module Lower = struct
  let make_clear ~path : lower = Clear { path }

  let make_luks ?(primary_key = Rand_utils.gen_rand_string ~len:4096)
      ?(add_secondary_key = false) ?(version = `LuksV2) ~path ~mapper_name
      enc_params : lower =
    let luks : Luks_info.t =
      {
        enc_params =
          Option.value
            ~default:
              ( { iter_time_ms = None; key_size_bits = None }
                : Luks_info.enc_params )
            enc_params;
        primary_key;
        secondary_key =
          ( if add_secondary_key then Some (Rand_utils.gen_rand_string ~len:4096)
            else None );
        version;
        mapper_name;
        state = `Luks_closed;
      }
    in
    Luks { luks; path }

  let mount (t : t) =
    match t.lower with
    | Clear _ -> ()
    | Luks { luks; path } ->
      assert (luks.state = `Luks_closed);
      let stdin, f =
        Printf.sprintf "cryptsetup open --key-file=- %s %s" path
          luks.mapper_name
        |> exec_with_stdin
      in
      output_string stdin luks.primary_key;
      f ();
      luks.state <- `Luks_opened

  let unmount (t : t) =
    match t.lower with
    | Clear _ -> ()
    | Luks { luks; _ } ->
      assert (luks.state = `Luks_opened);
      Printf.sprintf "cryptsetup close %s" luks.mapper_name |> exec;
      luks.state <- `Luks_closed

  let set_up t =
    match t.lower with
    | Clear _ -> ()
    | Luks { luks; path } -> (
        let iter_time_ms_opt =
          Option.map
            (fun x -> [ "--iter-time"; string_of_int x ])
            luks.enc_params.iter_time_ms
          |> Option.value ~default:[]
        in
        let key_size_bits_opt =
          Option.map
            (fun x -> [ "--key-size"; string_of_int x ])
            luks.enc_params.key_size_bits
          |> Option.value ~default:[]
        in
        (let stdin, f =
           String.concat " "
             ( [
               "cryptsetup";
               "luksFormat";
               "-y";
               "--key-file=-";
               "--type";
               Printf.sprintf "luks%d" (luks_version_to_int luks.version);
             ]
               @ iter_time_ms_opt @ key_size_bits_opt @ [ path ] )
           |> exec_with_stdin
         in
         output_string stdin luks.primary_key;
         f ());
        match luks.secondary_key with
        | None -> ()
        | Some secondary_key ->
          let tmp_path = Filename.temp_file "installer" "secondary_key" in
          let tmp_oc = open_out tmp_path in
          Fun.protect
            ~finally:(fun () -> close_out tmp_oc)
            (fun () -> output_string tmp_oc secondary_key);
          let stdin, f =
            String.concat " "
              [
                "cryptsetup";
                "luksAddKey";
                "-y";
                "--key-file=-";
                path;
                tmp_path;
              ]
            |> exec_with_stdin
          in
          output_string stdin luks.primary_key;
          f () )
end

module Mid = struct
  let make_mid_none () = None

  let make_mid_lvm ~lv_name ~vg_name = Some { lv_name; vg_name }
end

module Upper = struct
  let make ~mount_point fs = { mount_point; fs }

  let mount (t : t) =
    let { mount_point; _ } = t.upper in
    let mid_path = path_to_mid_for_upper t in
    Printf.sprintf "mount %s %s" mid_path mount_point |> exec

  let unmount (t : t) =
    let { mount_point; _ } = t.upper in
    Printf.sprintf "umount %s" mount_point |> exec

  let set_up t =
    let format_cmd fs part =
      match fs with
      | `Fat32 -> Printf.sprintf "mkfs.fat -F32 %s" part
      | `Ext4 -> Printf.sprintf "mkfs.ext4 %s" part
    in
    format_cmd t.upper.fs (path_to_mid_for_upper t) |> exec
end

let set_up t =
  Lower.set_up t;
  Upper.set_up t

let mount t =
  Lower.mount t;
  Upper.mount t

let unmount t =
  Upper.unmount t;
  Lower.unmount t

let make lower mid upper = { upper; mid; lower; state = `Unformatted }
