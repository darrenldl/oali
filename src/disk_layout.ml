type lvm_info = {
  (* vg_pv_map : string list String_map.t; *)
  vg_name : string;
  pv_name : string list;
}

type t = {
  root : Storage_unit.t;
  var : Storage_unit.t option;
  home : Storage_unit.t option;
  (* swap : Storage_unit.t option; *)
  boot : Storage_unit.t;
  esp : Storage_unit.t option;
  lvm_info : lvm_info option;
  pool : Storage_unit.pool;
}

type layout_choice =
  | Single_disk
  | Sys_part_plus_boot_plus_maybe_EFI
  | Sys_part_plus_usb_drive
  | Lvm_single_disk
  | Lvm_boot_plus_maybe_EFI_plus_pv_s
  | Lvm_usb_drive_plus_pv_s

(* let make_lower ~disk ~part_num = {disk; part_num} *)

(* let lower_part_to_cmd_string {disk; part_num} =
 *   sprintf "/dev/%s%d" disk part_num *)

(* let luks_to_mapper_name_cmd_string { mapper_name; _ } =
 *   Printf.sprintf "/dev/mapper/%s" mapper_name *)

(* let luks_open { lower; upper; _ } =
 *   match upper with
 *   | Plain_FS _ -> failwith "LUKS expected"
 *   | Luks luks ->
 *     assert (luks.state = Luks_closed);
 *     let stdin, f =
 *       Printf.sprintf "cryptsetup open --key-file=- %s %s" lower.path
 *         luks.mapper_name
 *       |> exec_with_stdin
 *     in
 *     output_string stdin luks.primary_key;
 *     f ();
 *     luks.state <- Luks_opened *)

(* let luks_close { upper; _ } =
 *   match upper with
 *   | Plain_FS _ -> failwith "LUKS expected"
 *   | Luks luks ->
 *     assert (luks.state = Luks_opened);
 *     Printf.sprintf "cryptsetup close %s" luks.mapper_name |> exec;
 *     luks.state <- Luks_closed *)

(* let mount_part ({ lower; upper; state } as p) ~mount_point =
 *   assert (state = Unmounted);
 *   ( match upper with
 *     | Plain_FS _ -> Printf.sprintf "mount %s %s" lower.path mount_point |> exec
 *     | Luks luks ->
 *       luks_open { lower; upper; state };
 *       Printf.sprintf "mount %s %s"
 *         (luks_to_mapper_name_cmd_string luks)
 *         mount_point
 *       |> exec );
 *   p.state <- Mounted *)

(* let unmount_part ({ lower; upper; state } as p) =
 *   assert (state = Mounted);
 *   ( match upper with
 *     | Plain_FS _ -> Printf.sprintf "umount %s" lower.path |> exec
 *     | Luks luks ->
 *       let mapper_name = luks_to_mapper_name_cmd_string luks in
 *       Printf.sprintf "umount %s" mapper_name |> exec;
 *       p.state <- Unmounted;
 *       luks_close { lower; upper; state } );
 *   p.state <- Unmounted *)

(* let format_cmd fs part =
 *   match fs with
 *   | Fat32 -> Printf.sprintf "mkfs.fat -F32 %s" part
 *   | Ext4 -> Printf.sprintf "mkfs.ext4 %s" part *)

(* let format_part ({ upper; lower; state } as p) =
 *   assert (state = Unformatted);
 *   ( match upper with
 *     | Plain_FS fs -> format_cmd fs lower.path |> exec
 *     | Luks luks ->
 *       let iter_time_ms_opt =
 *         Option.map
 *           (fun x -> [ "--iter-time"; string_of_int x ])
 *           luks.enc_params.iter_time_ms
 *         |> Option.value ~default:[]
 *       in
 *       let key_size_bits_opt =
 *         Option.map
 *           (fun x -> [ "--key-size"; string_of_int x ])
 *           luks.enc_params.key_size_bits
 *         |> Option.value ~default:[]
 *       in
 *       (let stdin, f =
 *          String.concat " "
 *            ( [
 *              "cryptsetup";
 *              "luksFormat";
 *              "-y";
 *              "--key-file=-";
 *              "--type";
 *              Printf.sprintf "luks%d" (luks_version_to_int luks.version);
 *            ]
 *              @ iter_time_ms_opt @ key_size_bits_opt @ [ lower.path ] )
 *          |> exec_with_stdin
 *        in
 *        output_string stdin luks.primary_key;
 *        f ());
 *       ( match luks.secondary_key with
 *         | None -> ()
 *         | Some secondary_key ->
 *           let tmp_path = Filename.temp_file "installer" "secondary_key" in
 *           let tmp_oc = open_out tmp_path in
 *           Fun.protect
 *             ~finally:(fun () -> close_out tmp_oc)
 *             (fun () -> output_string tmp_oc secondary_key);
 *           let stdin, f =
 *             String.concat " "
 *               [
 *                 "cryptsetup";
 *                 "luksAddKey";
 *                 "-y";
 *                 "--key-file=-";
 *                 lower.path;
 *                 tmp_path;
 *               ]
 *             |> exec_with_stdin
 *           in
 *           output_string stdin luks.primary_key;
 *           f () );
 *       luks_open p;
 *       let mapper_name = luks_to_mapper_name_cmd_string luks in
 *       exec (format_cmd luks.inner_fs mapper_name);
 *       luks_close p );
 *   p.state <- Unmounted *)

(* let format layout =
 *   Option.iter format_part layout.esp_part;
 *   format_part layout.boot_part;
 *   format_part layout.sys_part *)

(* let make_luks ~enc_params ?(primary_key = Rand_utils.gen_rand_string ~len:4096)
 *     ?(add_secondary_key = false) ?(version = LuksV2) inner_fs ~mapper_name =
 *   {
 *     enc_params =
 *       Option.value
 *         ~default:{ iter_time_ms = None; key_size_bits = None }
 *         enc_params;
 *     primary_key;
 *     secondary_key =
 *       ( if add_secondary_key then Some (Rand_utils.gen_rand_string ~len:4096)
 *         else None );
 *     version;
 *     inner_fs;
 *     mapper_name;
 *     state = Luks_closed;
 *   } *)

(* let make_part ~path upper =
 *   let lower = { path } in
 *   { lower; upper; state = Unformatted } *)

module Params = struct
  let esp_lower_id = 0
  let esp_mid_id = 0

  let boot_lower_id = 1
  let boot_mid_id = 1

  let sys_lower_id = 2
  let sys_mid_id = 2
end

let make_esp (pool : Storage_unit.pool) ~path =
  let lower_id = Params.esp_lower_id in
  let mid_id = Params.esp_mid_id in
  Hashtbl.add pool.lower_pool lower_id
    (Storage_unit.Lower.make_clear ~path);
  Hashtbl.add pool.mid_pool mid_id (Storage_unit.Mid.make_none ());
  let upper =
    Storage_unit.Upper.make ~mount_point:Config.esp_mount_point `Fat32
  in
  Storage_unit.make ~lower_id ~mid_id upper

let make_boot (pool : Storage_unit.pool) ~enc_params ~encrypt ~path =
  let lower_id = Params.boot_lower_id in
  let mid_id = Params.boot_mid_id in
  Hashtbl.add pool.lower_pool lower_id
    (if encrypt then
      let primary_key =
        Misc_utils.ask_string_confirm
          ~is_valid:(fun x -> x <> "")
          "Please enter passphrase for encryption"
      in
      Storage_unit.Lower.make_luks ~primary_key ~add_secondary_key:true
        ~version:`LuksV1 ~path ~mapper_name:Config.boot_mapper_name enc_params
    else Storage_unit.Lower.make_clear ~path
   );
  Hashtbl.add pool.mid_pool mid_id
    (Storage_unit.Mid.make_none ());
  let upper =
    Storage_unit.Upper.make ~mount_point:Config.boot_mount_point `Ext4
  in
  Storage_unit.make ~lower_id ~mid_id upper

let make_root_var_home (pool : Storage_unit.pool) ~enc_params ~encrypt ~use_lvm path : Storage_unit.t * Storage_unit.t option * Storage_unit.t option =
  let lower_id = Params.sys_lower_id in
  let mid_id = Params.sys_mid_id in
  Hashtbl.add pool.lower_pool lower_id
    (if encrypt then
      Storage_unit.Lower.make_luks ~path ~mapper_name:Config.sys_mapper_name
        enc_params
    else Storage_unit.Lower.make_clear ~path);
  Hashtbl.add pool.mid_pool mid_id
    (if use_lvm then
       let part_size_MiB = Disk_utils.disk_size_MiB path in
       let size_to_use_MiB =
         min
           (Config.lvm_lv_root_frac *. part_size_MiB)
           Config.lvm_lv_root_max_size_MiB
       in
       let size = Printf.sprintf "%dM" (int_of_float size_to_use_MiB) in
       Storage_unit.Mid.make_lvm ~lv_name:Config.lvm_lv_name_sys
         ~vg_name:Config.lvm_vg_name ~size
     else Storage_unit.Mid.make_none ());
  let upper =
    Storage_unit.Upper.make ~mount_point:Config.sys_mount_point `Ext4
  in
  let root = Storage_unit.make ~lower_id ~mid_id upper in
  (root, None, None)

let make_layout ~esp_part_path ~boot_part_path ~boot_part_enc_params
    ~boot_encrypt ~sys_part_path ~sys_part_enc_params ~sys_encrypt ~use_lvm =
  let pool = Storage_unit.make_pool () in
  let esp = Option.map (fun path -> make_esp pool ~path) esp_part_path in
  let boot =
    make_boot pool ~enc_params:boot_part_enc_params ~encrypt:boot_encrypt
      ~path:boot_part_path
  in
  let root, var, home =
    make_root_var_home pool ~enc_params:sys_part_enc_params ~encrypt:sys_encrypt
      ~use_lvm sys_part_path
  in
  let lvm_info =
    (* let vg_pv_map = String_map.empty |> String_map.add Config.lvm_vg_name [sys_part_path] in *)
    if use_lvm then
      Some { vg_name = Config.lvm_vg_name; pv_name = [ sys_part_path ] }
    else None
  in
  { root; var; home; esp; boot; lvm_info; pool }

let mount layout =
  Option.iter (Storage_unit.mount layout.pool) layout.esp;
  Storage_unit.mount layout.pool layout.boot;
  Storage_unit.mount layout.pool layout.root;
  Option.iter (Storage_unit.mount layout.pool) layout.var;
  Option.iter (Storage_unit.mount layout.pool) layout.home

let unmount layout =
  Option.iter (Storage_unit.unmount layout.pool) layout.esp;
  Storage_unit.unmount layout.pool layout.boot;
  Storage_unit.unmount layout.pool layout.root;
  Option.iter (Storage_unit.unmount layout.pool) layout.var;
  Option.iter (Storage_unit.unmount layout.pool) layout.home
