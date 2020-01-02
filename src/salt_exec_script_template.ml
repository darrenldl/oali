let gen ~use_usb_key =
  {|#!/bin/bash
|}
  ^ ( if use_usb_key then
        Printf.sprintf
          {|if [ ! -b /dev/mapper/"%s" ]; then
  echo "USB key does not seem to be mounted"
  echo "Please make sure you have mounted the USB key using %s"

  exit 1
fi

|}
          Config.boot_mapper_name Config.usb_key_mount_script_name
      else "" )
  ^ {|time=$(date "+%Y-%m-%d_%H:%M")
log_file_path=salt_exec_"$time".log

echo "Log is stored as $log_file_path"

salt-call --local state.apply |& tee -a $log_file_path
|}
