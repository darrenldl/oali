let tail start s =
  let len = String.length s in
  String.sub s start (len - start)
