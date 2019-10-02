open Proc_utils

let get_internet_facing_ip () =
  let res = exec_ret "ip route get 1.1.1.1" in
  let line = List.hd res.stdout in
  line |> String.split_on_char ' '
  |> List.filter (fun s -> s <> "")
  |> List.rev
  |> fun l -> List.nth l 2
