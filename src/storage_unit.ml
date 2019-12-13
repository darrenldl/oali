open Proc_utils

type fs =
  [ `Fat32
  | `Ext4
  ]

module Luks_info = struct
  type enc_params = {
    iter_time_ms : int option;
    key_size_bits : int option;
  }

  type luks_version =
    [ `LuksV1
    | `LuksV2
    ]

  type t = {
    enc_params : enc_params;
    primary_key : string;
    secondary_key : string option;
    version : luks_version;
    mapper_name : string;
  }
end

type state =
  [ `Fresh
  | `Mounted
  | `Unmounted
  ]

type l4 = {
  mount_point : string;
  fs : fs;
  mutable initialized : bool;
  mutable active_use_count : int;
}

type lvm_lv = {
  lv_name : string;
  vg_name : string;
  size_MiB : int option;
  mutable initialized : bool;
  mutable active_use_count : int;
}

type l3 = lvm_lv option

type lvm_vg = {
  vg_name : string;
  mutable initialized : bool;
  mutable active_use_count : int;
}

type l2 = lvm_vg option

type l1 =
  | Clear of { path : string }
  | Luks of {
      info : Luks_info.t;
      path : string;
      mutable initialized : bool;
      mutable active_use_count : int;
    }

type t = {
  l4_id : int;
  l3_id : int;
  l2_id : int;
  l1_id : int;
  mutable state : state;
}

type instance = {
  l4 : l4;
  l3 : l3;
  l2 : l2;
  l1 : l1;
}

type pool = {
  l4_pool : (int, l4) Hashtbl.t;
  l3_pool : (int, l3) Hashtbl.t;
  l2_pool : (int, l2) Hashtbl.t;
  l1_pool : (int, l1) Hashtbl.t;
}

let vgscan () =
  for _ = 0 to 1 do
    "vgscan" |> exec;
    Unix.sleep 2
  done

let make_pool () =
  {
    l4_pool = Hashtbl.create 100;
    l3_pool = Hashtbl.create 100;
    l2_pool = Hashtbl.create 100;
    l1_pool = Hashtbl.create 100;
  }

let luks_version_to_int ver = match ver with `LuksV1 -> 1 | `LuksV2 -> 2

let instantiate_from_pool (pool : pool) (t : t) : instance =
  {
    l4 = Hashtbl.find pool.l4_pool t.l4_id;
    l3 = Hashtbl.find pool.l3_pool t.l3_id;
    l2 = Hashtbl.find pool.l2_pool t.l2_id;
    l1 = Hashtbl.find pool.l1_pool t.l1_id;
  }

let path_to_l1_for_up pool (t : t) : string =
  let instance = instantiate_from_pool pool t in
  match instance.l1 with
  | Clear { path } -> path
  | Luks { info; _ } -> Printf.sprintf "/dev/mapper/%s" info.mapper_name

let path_to_l3_for_up pool (t : t) : string =
  let instance = instantiate_from_pool pool t in
  match instance.l3 with
  | None -> path_to_l1_for_up pool t
  | Some x -> Printf.sprintf "/dev/%s/%s" x.vg_name x.lv_name

module L1 = struct
  let make_clear ~path : l1 = Clear { path }

  let make_luks ?(primary_key = Rand_utils.gen_rand_string ~len:4096)
      ?(add_secondary_key = false) ?(version = `LuksV2) ~path ~mapper_name
      enc_params : l1 =
    let info : Luks_info.t =
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
      }
    in
    Luks { info; path; initialized = false; active_use_count = 0 }

  let mount pool (t : t) =
    let instance = instantiate_from_pool pool t in
    match instance.l1 with
    | Clear _ -> ()
    | Luks luks ->
      assert luks.initialized;
      if luks.active_use_count = 0 then (
        let stdin, f =
          Printf.sprintf "cryptsetup open --key-file=- %s %s" luks.path
            luks.info.mapper_name
          |> exec_with_stdin
        in
        output_string stdin luks.info.primary_key;
        f () );
      luks.active_use_count <- luks.active_use_count + 1

  let unmount pool (t : t) =
    let instance = instantiate_from_pool pool t in
    match instance.l1 with
    | Clear _ -> ()
    | Luks luks ->
      assert luks.initialized;
      assert (luks.active_use_count > 0);
      luks.active_use_count <- luks.active_use_count - 1;
      if luks.active_use_count = 0 then
        Printf.sprintf "cryptsetup close %s" luks.info.mapper_name |> exec

  let set_up pool t =
    let instance = instantiate_from_pool pool t in
    match instance.l1 with
    | Clear _ -> ()
    | Luks luks ->
      if not luks.initialized then (
        let iter_time_ms_opt =
          Option.map
            (fun x -> [ "--iter-time"; string_of_int x ])
            luks.info.enc_params.iter_time_ms
          |> Option.value ~default:[]
        in
        let key_size_bits_opt =
          Option.map
            (fun x -> [ "--key-size"; string_of_int x ])
            luks.info.enc_params.key_size_bits
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
               Printf.sprintf "luks%d"
                 (luks_version_to_int luks.info.version);
             ]
               @ iter_time_ms_opt @ key_size_bits_opt @ [ luks.path ] )
           |> exec_with_stdin
         in
         output_string stdin luks.info.primary_key;
         f ());
        ( match luks.info.secondary_key with
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
                  luks.path;
                  tmp_path;
                ]
              |> exec_with_stdin
            in
            output_string stdin luks.info.primary_key;
            f () );
        luks.initialized <- true )

  let reset pool t =
    let instance = instantiate_from_pool pool t in
    match instance.l1 with
    | Clear _ -> ()
    | Luks luks ->
      luks.initialized <- false;
      luks.active_use_count <- 0
end

module L2 = struct
  let make_none () : l2 = None

  let make_lvm ~vg_name : l2 =
    Some { vg_name; initialized = false; active_use_count = 0 }

  let mount pool (t : t) =
    let instance = instantiate_from_pool pool t in
    match instance.l2 with
    | None -> ()
    | Some lvm_vg ->
      assert lvm_vg.initialized;
      if lvm_vg.active_use_count = 0 then (
        vgscan ();
        Printf.sprintf "vgchange -ay %s" lvm_vg.vg_name |> exec );
      lvm_vg.active_use_count <- lvm_vg.active_use_count + 1

  let unmount pool (t : t) =
    let instance = instantiate_from_pool pool t in
    match instance.l2 with
    | None -> ()
    | Some lvm_vg ->
      assert lvm_vg.initialized;
      assert (lvm_vg.active_use_count > 0);
      lvm_vg.active_use_count <- lvm_vg.active_use_count - 1;
      if lvm_vg.active_use_count = 0 then (
        vgscan ();
        Printf.sprintf "vgchange -an %s" lvm_vg.vg_name |> exec )

  let set_up pool t : unit =
    let instance = instantiate_from_pool pool t in
    match instance.l2 with
    | None -> ()
    | Some lvm_vg ->
      if not lvm_vg.initialized then (
        let pv_name = path_to_l1_for_up pool t in
        Printf.sprintf "pvcreate -ff %s" pv_name |> exec;
        Printf.sprintf "vgcreate -ff %s %s" lvm_vg.vg_name pv_name |> exec;
        lvm_vg.initialized <- true;
        lvm_vg.active_use_count <- lvm_vg.active_use_count + 1;
        unmount pool t )

  let reset pool t =
    let instance = instantiate_from_pool pool t in
    match instance.l2 with
    | None -> ()
    | Some lvm_vg ->
      lvm_vg.initialized <- false;
      lvm_vg.active_use_count <- 0
end

module L3 = struct
  let make_none () : l3 = None

  let make_lvm ~lv_name ~vg_name ~size_MiB : l3 =
    Some
      { lv_name; vg_name; size_MiB; initialized = false; active_use_count = 0 }

  let mount pool t : unit =
    let instance = instantiate_from_pool pool t in
    match instance.l3 with
    | None -> ()
    | Some lvm_lv ->
      assert lvm_lv.initialized;
      if lvm_lv.active_use_count = 0 then (
        vgscan ();
        Printf.sprintf "lvchange -ay %s/%s" lvm_lv.vg_name lvm_lv.lv_name
        |> exec );
      lvm_lv.active_use_count <- lvm_lv.active_use_count + 1

  let unmount pool t : unit =
    let instance = instantiate_from_pool pool t in
    match instance.l3 with
    | None -> ()
    | Some lvm_lv ->
      assert lvm_lv.initialized;
      assert (lvm_lv.active_use_count > 0);
      if lvm_lv.active_use_count = 0 then (
        vgscan ();
        Printf.sprintf "lvchange -an %s/%s" lvm_lv.vg_name lvm_lv.lv_name
        |> exec )

  let set_up pool t : unit =
    let instance = instantiate_from_pool pool t in
    match instance.l3 with
    | None -> ()
    | Some lvm_lv ->
      if not lvm_lv.initialized then (
        ( match lvm_lv.size_MiB with
          | None ->
            Printf.sprintf "lvcreate -l 100%%FREE %s -n %s" lvm_lv.vg_name
              lvm_lv.lv_name
          | Some size_MiB ->
            Printf.sprintf "lvcreate -L %dM %s -n %s" size_MiB lvm_lv.vg_name
              lvm_lv.lv_name )
        |> exec;
        lvm_lv.initialized <- true;
        lvm_lv.active_use_count <- lvm_lv.active_use_count + 1;
        unmount pool t )

  let reset pool t =
    let instance = instantiate_from_pool pool t in
    match instance.l3 with
    | None -> ()
    | Some lvm_lv ->
      lvm_lv.initialized <- false;
      lvm_lv.active_use_count <- 0
end

module L4 = struct
  let make ~mount_point fs =
    { mount_point; fs; initialized = false; active_use_count = 0 }

  let mount pool (t : t) =
    let l4 = (instantiate_from_pool pool t).l4 in
    assert l4.initialized;
    assert (l4.active_use_count = 0);
    let l3_path = path_to_l3_for_up pool t in
    ( try Unix.mkdir l4.mount_point 0o744
      with Unix.Unix_error (Unix.EEXIST, _, _) -> () );
    Printf.sprintf "mount %s %s" l3_path l4.mount_point |> exec;
    l4.active_use_count <- l4.active_use_count + 1

  let unmount pool (t : t) =
    let l4 = (instantiate_from_pool pool t).l4 in
    assert l4.initialized;
    assert (l4.active_use_count = 1);
    Printf.sprintf "umount %s" l4.mount_point |> exec;
    l4.active_use_count <- l4.active_use_count - 1

  let set_up pool t =
    let l4 = (instantiate_from_pool pool t).l4 in
    if not l4.initialized then (
      let format_cmd fs part =
        match fs with
        | `Fat32 -> Printf.sprintf "mkfs.fat -F32 %s" part
        | `Ext4 -> Printf.sprintf "mkfs.ext4 %s" part
      in
      format_cmd l4.fs (path_to_l3_for_up pool t) |> exec;
      l4.initialized <- true )

  let reset pool t =
    let l4 = (instantiate_from_pool pool t).l4 in
    l4.initialized <- false;
    l4.active_use_count <- 0
end

let mount pool t =
  assert (t.state = `Unmounted);
  L1.mount pool t;
  L2.mount pool t;
  L3.mount pool t;
  L4.mount pool t;
  t.state <- `Mounted

let unmount pool t =
  assert (t.state = `Mounted);
  L4.unmount pool t;
  L3.unmount pool t;
  L2.unmount pool t;
  L1.unmount pool t;
  t.state <- `Unmounted

let set_up pool t =
  assert (t.state = `Fresh);
  (* L1 set up and mount *)
  L1.set_up pool t;
  L1.mount pool t;
  (* L2 set up and mount *)
  L2.set_up pool t;
  L2.mount pool t;
  (* L3 set up and mount *)
  L3.set_up pool t;
  L3.mount pool t;
  (* L4 set up *)
  L4.set_up pool t;
  (* unmount L3 to L1 *)
  L3.unmount pool t;
  L2.unmount pool t;
  L1.unmount pool t;
  t.state <- `Unmounted

let make ~l1_id ~l2_id ~l3_id ~l4_id =
  { l1_id; l2_id; l3_id; l4_id; state = `Fresh }

let reset pool t =
  L4.reset pool t;
  L3.reset pool t;
  L2.reset pool t;
  L1.reset pool t;
  t.state <- `Fresh
