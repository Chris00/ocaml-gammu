OCAMLPACKS     = gammu unix
OCAMLC_FLAGS   = -dtypes -g
OCAMLOPT_FLAGS = 

DEMO_LIBS = utils_demo.cma
TESTS     = $(DEMO_LIBS) $(wildcard test_*.ml demo_*.ml)

.PHONY: all byte native
all: byte native
byte: $(TESTS:.ml=.exe)
native: $(patsubst %.cma,%.cmxa, $(TESTS:.ml=.com))

utils_demo.cma: utils_demo.cmo
utils_demo.cmxa: utils_demo.cmx

demo_incoming.exe: $(DEMO_LIBS)
demo_incoming.com: $(DEMO_LIBS:.cma=.cmxa)
demo_getfirstsms.exe: $(DEMO_LIBS)
demo_getfirstsms.com: $(DEMO_LIBS:.cma=.cmxa)

include ../Makefile.ocaml
