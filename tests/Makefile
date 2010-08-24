OCAMLPACKS     = gammu unix
OCAMLC_FLAGS   = -dtypes -g
OCAMLOPT_FLAGS = 

DEMO_LIBS = args_demo.cma utils_tests.cma
TESTS     = $(DEMO_LIBS) $(wildcard test_*.ml demo_*.ml)

.PHONY: all byte native
all: byte native
byte: $(TESTS:.ml=.exe)
native: $(patsubst %.cma,%.cmxa, $(TESTS:.ml=.com))

args_demo.cma: args_demo.cmo
args_demo.cmxa: args_demo.cmx
utils_tests.cma: utils_tests.cmo
utils_tests.cmxa: utils_tests.cmx

demo_incoming.exe: $(DEMO_LIBS)
demo_incoming.com: $(DEMO_LIBS:.cma=.cmxa)
demo_readsms.exe: $(DEMO_LIBS)
demo_readsms.com: $(DEMO_LIBS:.cma=.cmxa)
demo_readall.exe: $(DEMO_LIBS)
demo_readall.com: $(DEMO_LIBS:.cma=.cmxa)
demo_infos.exe: $(DEMO_LIBS)
demo_infos.com: $(DEMO_LIBS:.cma=.cmxa)

include ../Makefile.ocaml
