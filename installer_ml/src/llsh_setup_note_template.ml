let gen_w_usb_key () = Printf.sprintf
    {|# This file is from %s setup
# See %s for details .

The following scripts should be present in /root directory
    %s
        Apply installed local salt states
            NOTE :
              Please mount the USB key first (using %s)
              before using
            Setup should have installed the appropriate salt states
            in your system already

    %s
        Mounts USB key to system
            Plug in your USB key and execute this before system update
            or any maintenance

    %s
        Unmounts USB key
            Execute this and remove your USB key after update
            or any maintenance

    %s
        Helper script for using useradd
            Add user in same manner as used by setup.sh
            Add user to groups : users,wheel,rfkill

    %s
        Helper script for using useradd
            Add user in same manner as used by setup.sh
            Add user to groups : users,rfkill
|}
    Config.repo_name
    Config.repo_url
    Config.salt_exec_script_name
    Config.usb_key_mount_script_name
    Config.usb_key_mount_script_name
    Config.usb_key_unmount_script_name
    Config.useradd_helper_as_powerful_name
    Config.useradd_helper_restricted_name

let gen_no_usb_key () = Printf.sprintf
    {|# This file is from %s setup
# See %s for details .

The following scripts should be present in /root directory
    %s
        Apply installed local salt states
            Setup should have installed the appropriate salt states
            in your system already

    %s
        Helper script for using useradd
            Add user in same manner as used by setup.sh
            Add user to groups : users,wheel,rfkill

    %s
        Helper script for using useradd
            Add user in same manner as used by setup.sh
            Add user to groups : users,rfkill
|}
    Config.repo_name
    Config.repo_url
    Config.salt_exec_script_name
    Config.useradd_helper_as_powerful_name
    Config.useradd_helper_restricted_name
