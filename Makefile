WEB_DOC = forge.ocamlcore.org:/home/groups/ml-gammu/htdocs/

.PHONY: all byte native install uninstall reinstall tests doc web
all: byte native
byte native install uninstall reinstall doc:
	$(MAKE) -C src $@

tests: all
	$(MAKE) -C tests all

web: doc
	scp -C -r doc $(WEB_DOC)

.PHONY: svn
svn:
	bzr push svn+ssh://scm.ocamlcore.org/svnroot/ml-gammu/trunk

clean:
	$(MAKE) -C src $@
	$(MAKE) -C tests $@
