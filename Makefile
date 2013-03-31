PKGNAME	    = $(shell oasis query name)
PKGVERSION  = $(shell oasis query version)
PKG_TARBALL = $(PKGNAME)-$(PKGVERSION).tar.gz

WEB = forge.ocamlcore.org:/home/groups/ml-gammu/htdocs/

DISTFILES   = AUTHORS.txt INSTALL.txt README.txt COPYING.txt _oasis \
  Makefile myocamlbuild.ml setup.ml config.ml _tags src/ \
  $(wildcard demo/*.ml) demo/gammurc

.PHONY: all byte native configure doc install uninstall reinstall upload-doc

all byte native setup.log: configure
	ocaml setup.ml -build

configure: setup.data
setup.data: setup.ml
	ocaml $< -configure

setup.ml: _oasis
	oasis setup -setup-update dynamic

doc install uninstall reinstall: setup.log
	ocaml setup.ml -$@

upload-doc: doc
	scp -C -p -r _build/src/API.docdir/ $(WEB)

# Make a tarball
.PHONY: dist tar
dist tar: $(DISTFILES)
	mkdir $(PKGNAME)-$(PKGVERSION)
	cp --parents -r $(DISTFILES) $(PKGNAME)-$(PKGVERSION)/
#	Full setup.ml, independent of oasis
	cd $(PKGNAME)-$(PKGVERSION) && oasis setup
	tar -zcvf $(PKG_TARBALL) $(PKGNAME)-$(PKGVERSION)
	rm -rf $(PKGNAME)-$(PKGVERSION)

.PHONY: clean distclean
clean::
	ocaml setup.ml -clean
	$(RM) $(PKG_TARBALL)

distclean: clean
	ocaml setup.ml -distclean
	$(RM) $(wildcard *.ba[0-9] *.bak *~ *.odocl)
