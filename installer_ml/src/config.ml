let sys_mount_point = "/mnt"

let esp_mount_point = Printf.sprintf "%s/efi" sys_mount_point

let boot_mount_point = Printf.sprintf "%s/boot" sys_mount_point

let sys_part_keyfile_name = "sys_part.key"

let boot_part_keyfile_name = "boot_part.key"

let boot_mapper_name = "crypt_boot"

let root_mapper_name = "crypt_root"

let llsh_files_dir_path = "/root/llsh_pack"

let useradd_helper1_name = "useradd_helper_as_powerful.sh"

let useradd_helper2_name = "useradd_helper_restricted.sh"
