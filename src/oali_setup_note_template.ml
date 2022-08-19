let gen ~use_usb_key =
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
%s    %s
        Helper script for using useradd
            Add user in same manner as used by setup.sh
            Add user to groups : users,wheel,rfkill

    %s
        Helper script for using useradd
            Add user in same manner as used by setup.sh
            Add user to groups : users,rfkill
|}
    Config.repo_name Config.repo_url usb_key_text
    Config.useradd_helper_as_powerful_script_name
    Config.useradd_helper_restricted_script_name
