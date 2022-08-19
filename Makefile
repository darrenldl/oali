SRCFILES = src/*.ml*

OCPINDENT = ocp-indent \
	--inplace \
	$(SRCFILES)

.PHONY: all
all :
	dune build @all

.PHONY: release-static
release-static:
	OCAMLPARAM='_,ccopt=-static' dune build --release src/oali.exe
	cp _build/default/src/oali.exe oali

.PHONY: format
format :
	$(OCPINDENT)

.PHONY: cinaps
cinaps :
	cinaps -i $(SRCFILES)
	$(OCAMLFORMAT)

.PHONY : clean
clean:
	dune clean
