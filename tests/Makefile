OCAMLPACKS     = unix
OCAMLC_FLAGS   = -dtypes -g
OCAMLOPT_FLAGS = 

OCAMLINCLUDES = ../src
LIBS_CMA      = gammu.cma args_demo.cma utils_tests.cma
LIBS_CMXA     = $(LIBS_CMA:.cma=.cmxa)
DEMO_LIBS     = args_demo.cma utils_tests.cma
TESTS         = $(DEMO_LIBS) $(wildcard test_*.ml demo_*.ml)

.PHONY: all byte native
all: byte native
byte: $(TESTS:.ml=.exe)
native: $(patsubst %.cma,%.cmxa, $(TESTS:.ml=.com))

args_demo.cma: args_demo.cmo
args_demo.cmxa: args_demo.cmx
utils_tests.cma: utils_tests.cmo
utils_tests.cmxa: utils_tests.cmx

include ../Makefile.ocaml
