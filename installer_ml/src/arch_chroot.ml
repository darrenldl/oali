let exec command =
  Proc_utils.exec
    (Printf.sprintf "arch-chroot %s %s" Config.sys_mount_point command)

let exec_no_capture command =
  Proc_utils.exec_no_capture
    (Printf.sprintf "arch-chroot %s %s" Config.sys_mount_point command)

let pacman s = exec_no_capture (Printf.sprintf "pacman --noconfirm %s" s)

let install pkgs =
  pacman (Printf.sprintf "--noconfirm -S %s" (String.concat " " pkgs))
