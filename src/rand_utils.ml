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

let gen_rand_alphanum_string ~len =
  let ic = open_in "/dev/urandom" in
  let rec aux ic acc len_left =
    if len_left = 0 then acc
    else
      let c = input_char ic in
      if Misc_utils.is_alphanum c then aux ic (c :: acc) (pred len_left)
      else aux ic acc len_left
  in
  let acc = aux ic [] len in
  close_in ic;
  CCString.of_list acc
