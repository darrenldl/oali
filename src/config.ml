let sys_mount_point = "/mnt"

let esp_part_size_MiB = 550.0

let esp_part_max_frac = 0.25

let efi_dir = "/efi"

let esp_mount_point = Misc_utils.concat_file_names [ sys_mount_point; efi_dir ]

let boot_part_size_MiB = 500.0

let boot_part_max_frac = 0.75

let total_disk_usage_frac = 0.75

let boot_dir = "/boot"

let boot_mount_point =
  Misc_utils.concat_file_names [ sys_mount_point; boot_dir ]

let sys_part_keyfile_name = "sys_part.key"

let boot_part_keyfile_name = "boot_part.key"

let boot_mapper_name = "crypt_boot"

let root_mapper_name = "crypt_root"

let livecd_mirrorlist_path =
  Misc_utils.concat_file_names [ "/etc"; "pacman.d"; "mirrorlist" ]

let etc_ssh_dir_path =
  Misc_utils.concat_file_names [ sys_mount_point; "etc"; "ssh" ]

let oali_files_dir_path = Misc_utils.concat_file_names [ "/root"; "oali_pack" ]

let useradd_helper_as_powerful_name = "useradd_helper_as_powerful.sh"

let useradd_helper_restricted_name = "useradd_helper_restricted.sh"

let oali_profiles_repo_url = "https://github.com/darrenldl/oali-profiles"

let repo_name = "oali"

let repo_url = "https://github.com/darrenldl/oali"

let salt_exec_script_name = "salt_exec.sh"

let usb_key_mount_script_name = "usb_key_mount.sh"

let usb_key_unmount_script_name = "usb_key_umount.sh"

let oali_setup_note_name = "oali_setup_note"

let oali_answer_store_dir = "oali_answers"

let sshd_config_path_in_repo =
  Misc_utils.concat_file_names [ "saltstack"; "salt"; "sshd_config" ]

let mkinitcpio_hooks =
  [
    "base";
    "udev";
    "autodetect";
    "keyboard";
    "keymap";
    "consolefont";
    "modconf";
    "block";
    "lvm2";
    "encrypt";
    "filesystems";
    "fsck";
  ]
