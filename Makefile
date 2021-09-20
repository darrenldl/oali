SRCFILES = src/*.ml*

OCAMLFORMAT = ocamlformat \
	--inplace \
	$(SRCFILES) \
	$(CINAPSFILES)

.PHONY: all
all :
	dune build @all

.PHONY: release-static
release-static:
	OCAMLPARAM='_,ccopt=-static' dune build --release src/oali.exe

.PHONY: format
format :
	$(OCAMLFORMAT)

.PHONY: cinaps
cinaps :
	cinaps -i $(SRCFILES)
	$(OCAMLFORMAT)

.PHONY : clean
clean:
	dune clean
