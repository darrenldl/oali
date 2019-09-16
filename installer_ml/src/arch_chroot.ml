let exec command =
  Proc_utils.exec (Printf.sprintf "arch-chroot /mnt %s" command)

let install pkgs =
  exec (Printf.sprintf "pacman --noconfirm -S %s" (String.concat " "pkgs))
