let gen_w_usb_key () =
  Printf.sprintf
    {|#!/bin/bash
if [ ! -b /dev/mapper/"%s" ]; then
  echo "USB key does not seem to be mounted"
  echo "Please make sure you have mounted the USB key using USB_KEY_MOUNT_SCRIPT_DUMMY"

  exit 1
fi

salt-call --local state.apply
|}
    Config.boot_mapper_name

let gen_no_usb_key () = {|#!/bin/bash

salt-call --local state.apply
|}
