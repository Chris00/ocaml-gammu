OCAMLPACKS = gammu unix
OCAMLC_FLAGS = -dtypes -g
OCAMLOPT_FLAGS = 

TESTS = $(wildcard test_*.ml demo_*.ml)

.PHONY: all byte native
all: byte native
byte: $(TESTS:.ml=.exe)
native: $(TESTS:.ml=.com)

include ../Makefile.ocaml
