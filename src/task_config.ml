type t = {
  disk_layout : Disk_layout.t option;
  disk_layout_choice : Disk_layout.layout_choice option;
  is_efi_mode : bool option;
  add_hardened : bool option;
  hardened_as_default : bool option;
  use_lvm : bool option;
  encrypt_boot : bool option;
  encrypt_sys : bool option;
  boot_part_enc_params : Storage_unit.Luks_info.enc_params option;
  sys_part_enc_params : Storage_unit.Luks_info.enc_params option;
  editor : string option;
  use_reflector : bool option;
  hostname : string option;
  enable_ssh_server : bool option;
  user_ssh_authorized_keys_path : string option;
  use_saltstack : bool option;
  user_name : string option;
  oali_profiles_repo_url : string option;
  oali_profiles_repo_name : string option;
  oali_profile : string option;
  do_unmount : bool option;
  do_shutdown : bool option;
}

let create () =
  {
    disk_layout = None;
    disk_layout_choice = None;
    is_efi_mode = None;
    add_hardened = None;
    hardened_as_default = None;
    use_lvm = None;
    encrypt_boot = None;
    encrypt_sys = None;
    boot_part_enc_params = None;
    sys_part_enc_params = None;
    editor = None;
    use_reflector = None;
    hostname = None;
    enable_ssh_server = None;
    user_ssh_authorized_keys_path = None;
    use_saltstack = None;
    user_name = None;
    oali_profiles_repo_url = None;
    oali_profiles_repo_name = None;
    oali_profile = None;
    do_unmount = None;
    do_shutdown = None;
  }
