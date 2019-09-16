let gen_rand_string ~len =
  let ic = open_in "/dev/urandom" in
  let s = Bytes.make len '\x00' in
  let total_len_read = ref 0 in
  while !total_len_read < len do
    let len_left = len - !total_len_read in
    let len_read = input ic s !total_len_read len_left in
    total_len_read := !total_len_read + len_read
  done;
  close_in ic;
  Bytes.to_string s
