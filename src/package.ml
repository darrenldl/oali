let install_to_mount_point ~mount_point packages =
  Arch_chroot.exec ~mount_point
    (Array.append [| "pacman"; "--noconfirm"; "-S" |] (Array.of_list packages))
