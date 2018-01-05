PKGVERSION = $(shell git describe --always --dirty)

build:
	jbuilder build @install --dev
	jbuilder build @demo --dev

install uninstall:
	jbuilder $@

doc:
	sed -e 's/%%VERSION%%/$(PKGVERSION)/' src/Root1D.mli \
	  > _build/default/src/Root1D.mli
	jbuilder build @doc
	echo '.def { background: #f9f9de; }' >> _build/default/_doc/odoc.css

lint:
	opam lint gammu.opam

clean:
	jbuilder clean

.PHONY: build install uninstall doc lint clean
