
.PHONY: all byte native install uninstall reinstall doc
all: byte native
byte native install uninstall reinstall doc:
	$(MAKE) -C src $@

.PHONY: tests
tests: all
	$(MAKE) -C tests all

clean:
	$(MAKE) -C src $@
	$(MAKE) -C tests $@
