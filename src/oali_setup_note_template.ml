let gen ~use_saltstack ~use_usb_key =
  let saltstack_text =
    if use_saltstack && use_usb_key then
      Printf.sprintf
        {|    %s
        Apply installed local salt states
            NOTE :
              Please mount the USB key first (using %s)
              before using
            Setup should have installed the appropriate salt states
            in your system already

|}
        Config.salt_exec_script_name Config.usb_key_mount_script_name
    else if use_saltstack && not use_usb_key then
      Printf.sprintf
        {|    %s
        Apply installed local salt states
            Setup should have installed the appropriate salt states
            in your system already

|}
        Config.salt_exec_script_name
    else ""
  in
  let usb_key_text =
    if use_usb_key then
      Printf.sprintf
        {|    %s
        Mounts USB key to system
            Plug in your USB key and execute this before system update
            or any maintenance

    %s
        Unmounts USB key
            Execute this and remove your USB key after update
            or any maintenance

|}
        Config.usb_key_mount_script_name Config.usb_key_unmount_script_name
    else ""
  in
  Printf.sprintf
    {|# This file is from %s setup
# See %s for details .

The following scripts should be present in /root directory
%s%s    %s
        Helper script for using useradd
            Add user in same manner as used by setup.sh
            Add user to groups : users,wheel,rfkill

    %s
        Helper script for using useradd
            Add user in same manner as used by setup.sh
            Add user to groups : users,rfkill
|}
    Config.repo_name Config.repo_url saltstack_text usb_key_text
    Config.useradd_helper_as_powerful_name Config.useradd_helper_restricted_name
