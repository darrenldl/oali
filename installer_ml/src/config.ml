let sys_mount_point = "/mnt"

let esp_part_size_MiB = 550.0

let esp_part_max_perc = 25.0

let efi_dir = "/efi"

let esp_mount_point = Misc_utils.concat_file_names [sys_mount_point; efi_dir]

let boot_part_size_MiB = 500.0

let boot_part_max_perc = 75.0

let boot_dir = "/boot"

let boot_mount_point = Misc_utils.concat_file_names [sys_mount_point; boot_dir]

let sys_part_keyfile_name = "sys_part.key"

let boot_part_keyfile_name = "boot_part.key"

let boot_mapper_name = "crypt_boot"

let root_mapper_name = "crypt_root"

let oli_files_dir_path = "/root/oli_pack"

let useradd_helper_as_powerful_name = "useradd_helper_as_powerful.sh"

let useradd_helper_restricted_name = "useradd_helper_restricted.sh"

let repo_url = "https://github.com/darrenldl/ocaml-linux-installer"

let repo_name = "ocaml-linux-installer"

let salt_exec_script_name = "salt_exec.sh"

let usb_key_mount_script_name = "usb_key_mount.sh"

let usb_key_unmount_script_name = "usb_key_umount.sh"

let oli_setup_note_name = "oli_setup_note"
