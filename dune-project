(lang dune 2.9)

(license "MIT")

(name oali)

(package
  (name oali)
  (synopsis "OCaml Arch Linux Installer")
  (description "
"
)
  (depends 
    (ocaml (>= "4.08.1"))
    dune
    cmdliner
    (containers (>= "3.6"))
  )
)
