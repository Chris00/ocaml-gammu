OCAMLPACKS     = unix gammu
OCAMLC_FLAGS   = -annot -g
OCAMLOPT_FLAGS = 
OCAMLINCLUDES = ../src
#GAMMU_CMA = gammu.cma

DEMO_LIBS = args_demo.ml utils_tests.ml
TESTS     = incoming_events.ml infos.ml readallsms.ml read1sms.ml

.PHONY: all byte native
all: byte native
byte: $(TESTS:.ml=.exe)
native: $(TESTS:.ml=.com)

$(TESTS:.ml=.exe): $(GAMMU_CMA) $(DEMO_LIBS:.ml=.cmo)
$(TESTS:.ml=.com): $(GAMMU_CMA:.cma=.cmxa) $(DEMO_LIBS:.ml=.cmx)

include ../Makefile.ocaml
