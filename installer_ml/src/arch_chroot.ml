let exec command ~mount_point =
  Proc_utils.exec (Array.append [|"arch-chroot"; mount_point|] command)
