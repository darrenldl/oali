open Proc_utils

type fs =
  | Fat32
  | Ext4

(* type inner =
 *   | Fs of fs
 *   | Lvm of lvm *)

type enc_params = {
  iter_time_ms : int option;
  key_size_bits : int option;
}

type luks_version =
  | LuksV1
  | LuksV2

type luks_state =
  | Luks_opened
  | Luks_closed

type luks = {
  enc_params : enc_params;
  primary_key : string;
  secondary_key : string option;
  version : luks_version;
  mapper_name : string;
  mutable state : luks_state;
}

(* type upper =
 *   | Plain_Fs of fs
 *   | Luks of luks *)

type state =
  | Unformatted
  | Mounted
  | Unmounted

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
  | Clear of { path : string}
  | Luks of {
      luks : luks;
      path : string
    }

type lvm_info = {
  vg_pv_map : string list String_map.t;
  vg_name : string;
  pv_name : string list;
}

type t =
  {
    upper : upper;
    mid : mid;
    lower : lower;
    mutable state : state;
  }

let luks_version_to_int ver = match ver with LuksV1 -> 1 | LuksV2 -> 2

let path_to_lower_for_mid (t : t) : string =
  match t.lower with
  | Clear {path } -> path
  | Luks { luks; _ } ->
    Printf.sprintf "/dev/mapper/%s" luks.mapper_name

let path_to_mid_for_upper (t : t) : string =
  match t.mid with
  | None -> path_to_lower_for_mid t
  | Some x ->
    Printf.sprintf "/dev/%s/%s" x.vg_name x.lv_name
