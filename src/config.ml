let root_mount_point = "/mnt"

let root_dir = "/root"

let esp_part_size_MiB = 550.0

let esp_part_max_frac = 0.25

let efi_dir = "/efi"

let esp_mount_point = String_utils.concat_file_names [ root_mount_point; efi_dir ]

let boot_part_size_MiB = 500.0

let boot_part_max_frac = 0.75

let boot_dir = "/boot"

let boot_mount_point =
  String_utils.concat_file_names [ root_mount_point; boot_dir ]

let keyfile_size = 4096

let sys_part_keyfile_name = "sys-part.key"

let boot_part_keyfile_name = "boot-part.key"

let boot_mapper_name = "crypt_boot"

let sys_mapper_name = "crypt_sys"

let livecd_mirrorlist_path =
  String_utils.concat_file_names [ "/etc"; "pacman.d"; "mirrorlist" ]

let etc_ssh_dir_path =
  String_utils.concat_file_names [ root_mount_point; "etc"; "ssh" ]

let etc_sshd_config_path =
  String_utils.concat_file_names [ etc_ssh_dir_path; "sshd_config" ]

let oali_files_dir_path = String_utils.concat_file_names [ "/root"; "oali-pack" ]

let useradd_helper_as_powerful_script_name = "useradd-helper-as-powerful.sh"

let useradd_helper_restricted_script_name = "useradd-helper-restricted.sh"

let repo_name = "oali"

let repo_url = "https://github.com/darrenldl/oali"

let usb_key_mount_script_name = "usb-key-mount.sh"

let usb_key_unmount_script_name = "usb-key-umount.sh"

let oali_setup_note_name = "oali-setup-note"

let oali_answer_store_dir = "oali-answers"

let sshd_port = 40010

let lvm_vg_name = "vg_sys"

let lvm_lv_root_name = "lv_root"

let lvm_lv_root_frac = 0.25

let lvm_lv_root_max_size_MiB = 25. *. 1024.

let lvm_lv_var_name = "lv_var"

let lvm_lv_var_frac = 0.25

let lvm_lv_var_max_size_MiB = 250. *. 1024.

let lvm_lv_home_name = "lv_home"

let lvm_lv_home_frac_of_leftover = 0.8

let var_mount_point = String_utils.concat_file_names [ root_mount_point; "var" ]

let home_mount_point = String_utils.concat_file_names [ root_mount_point; "home" ]

let doc_md_name = "OALI_DOC.md"

let recovery_kit_dir = "oali-recovery-kit"

let boot_part_luks_header_backup_file_name = "boot-luks-header.img"

let root_part_luks_header_backup_file_name = "root-luks-header.img"

let boot_disk_part_table_backup_prefix = "boot-disk-part-table"

let sys_disk_part_table_backup_prefix = "sys-disk-part-table"

let gpt_sgdisk_backup_suffix = ".gpt.sgdisk"

let mbr_sfdisk_backup_suffix = ".mbr.sfdisk"
