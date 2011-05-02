PKGNAME	    = $(shell oasis query name)
PKGVERSION  = $(shell oasis query version)
PKG_TARBALL = $(PKGNAME)-$(PKGVERSION).tar.gz

WEB = forge.ocamlcore.org:/home/groups/ml-gammu/htdocs/

DISTFILES   = AUTHORS.txt INSTALL.txt README.txt _oasis \
  _tags src/META Makefile setup.ml src/API.odocl \
  src/gammu.mllib src/libgammu.clib \
  $(wildcard src/*.ml) $(wildcard src/*.mli) \
  $(wildcard tests/*.ml) tests/gammurc

.PHONY: all byte native configure doc install uninstall reinstall upload-doc

all byte native: configure
	ocaml setup.ml -build

configure: setup.ml
	ocaml $< -configure

setup.ml: _oasis
	oasis setup

doc install uninstall reinstall:
	ocaml setup.ml -$@

upload-doc: doc
	scp -C -p -r _build/src/API.docdir/ $(WEB)

# Make a tarball
.PHONY: dist tar
dist tar: $(DISTFILES)
	mkdir $(PKGNAME)-$(PKGVERSION)
	cp -r $(DISTFILES) $(PKGNAME)-$(PKGVERSION)/
	tar -zcvf $(PKG_TARBALL) $(PKGNAME)-$(PKGVERSION)
	rm -rf $(PKGNAME)-$(PKGVERSION)


.PHONY: svn
svn:
	bzr push svn+ssh://scm.ocamlcore.org/svnroot/ml-gammu/trunk

.PHONY: clean distclean
clean::
	ocaml setup.ml -clean
	$(RM) $(PKG_TARBALL)

distclean:
	ocaml setup.ml -distclean
	$(RM) $(wildcard *.ba[0-9] *.bak *~ *.odocl) setup.log
