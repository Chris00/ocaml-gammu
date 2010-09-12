OCAMLPACKS     = gammu unix
OCAMLC_FLAGS   = -dtypes -g
OCAMLOPT_FLAGS = 

DEMO_LIBS = args_demo.ml utils_tests.ml
TESTS     = $(wildcard test_*.ml demo_*.ml)

.PHONY: all byte native
all: byte native
byte: $(TESTS:.ml=.exe)
native: $(TESTS:.ml=.com)

$(TESTS:.ml=.exe): $(DEMO_LIBS:.ml=.cmo)
$(TESTS:.ml=.com): $(DEMO_LIBS:.ml=.cmx)

include ../Makefile.ocaml
