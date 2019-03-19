PKGVERSION = $(shell git describe --always)

build:
	dune build @install @demo

install uninstall:
	dune $@

doc:
	dune build @doc
	sed -e 's/%%VERSION%%/$(PKGVERSION)/' --in-place \
	  _build/default/_doc/_html/gammu/Gammu/index.html

lint:
	opam lint gammu.opam

clean:
	dune clean

.PHONY: build install uninstall doc lint clean
