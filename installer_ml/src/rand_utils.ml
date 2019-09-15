let gen_rand_string =
  let initialised = ref false in
  fun ~len ->
    if not !initialised then Nocrypto_entropy_unix.initialize ();
    Nocrypto.Rng.generate len