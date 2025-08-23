BUILD=../build

# Choose scripting language: perl or python
SCRIPT_LANG ?= python

# CC65 source directory for manifest file copying (loose coupling)
CC65_SRC ?= ../../cc65

LD=ld65
LDOPT=-v -vm
CC=cc65
CCOPT=-D BBC_CLIB -g -T -O -Or -r -I libsrc/bbc -I libsrc/runtime
AS=ca65
ASOPT=-t bbc -D BBC_CLIB
AR=ar65

# Script selection based on SCRIPT_LANG
ifeq ($(SCRIPT_LANG),perl)
    CLIB_IMPORTS_SCRIPT = perl clib_imports.pl
    CLIB_STUBS_SCRIPT = perl clib_stubs.pl
else ifeq ($(SCRIPT_LANG),python)
    CLIB_IMPORTS_SCRIPT = python3 clib_imports.py
    CLIB_STUBS_SCRIPT = python3 clib_stubs.py
else
    $(error SCRIPT_LANG must be either 'perl' or 'python')
endif

RTDIR=libsrc/runtime
COMDIR=libsrc/common
BBCDIR=libsrc/bbc
RTSRCS=$(wildcard $(RTDIR)/*.s) 
COMSRCS=$(shell find $(COMDIR) -iname "*.s" -o -iname "*.c")
BBCSRCS=$(shell find $(BBCDIR) -iname "*.s" -o -iname "*.c")
SRCSNOP=$(COMSRCS:$(COMDIR)/%=%) $(RTSRCS:$(RTDIR)/%=%) $(BBCSRCS:$(BBCDIR)/%=%)

WRK=$(BUILD)/libwrk


OBJS=$(addprefix $(WRK)/, $(patsubst %.c, %.o, $(patsubst %.s,%.o,$(SRCSNOP))))
INFOS=$(patsubst %.o, %.info, $(OBJS))

CLIB_RTIMPORT=$(WRK)/clib_imports.inc
CLIB_RTJUMPS=$(WRK)/clib_imports_jmp.inc
CLIB_OBJS_LST=$(WRK)/clib_include_objs.lst
CLIB_STUBS_LST=$(WRK)/clib_include_lib_objs.lst
CLIB_INCS= $(CLIB_RTIMPORT) $(CLIB_RTJUMPS) $(CLIB_OBJS_LST) $(CLIB_STUBS_LST)


X:=$(shell mkdir -p $(BUILD))
X:=$(shell mkdir -p $(WRK))
X:=$(shell mkdir -p $(WRK)/oslib)


.PHONY:clean all copy-manifests 

all:: $(OBJS) $(BUILD)/clib.rom $(WRK)/clib_stubs.s $(BUILD)/clib.lib $(BUILD)/clib.lbl $(BUILD)/clib-mos.lbl copy-manifests | $(WRK) $(WRK)/oslib

clean::
	-rm -r $(WRK) 2>/dev/null
	-rm $(BUILD)/clib.rom 2>/dev/null
	-rm $(BUILD)/clib.lib 2>/dev/null
	-rm $(BUILD)/clib.map 2>/dev/null
	-rm $(BUILD)/clib.lbl 2>/dev/null
	-rm $(BUILD)/clib-mos.lbl 2>/dev/null


$(WRK)/clib_rom.o: clib_rom.s $(CLIB_INCS)
	$(AS) $(ASOPT) -I $(WRK) -o $@ $<

$(CLIB_INCS): $(RTSRCS) clib_imports.pl clib_imports.py $(WRK) $(OBJS) $(INFOS) 
	$(CLIB_IMPORTS_SCRIPT) $(CLIB_RTIMPORT) $(CLIB_RTJUMPS) $(CLIB_OBJS_LST) $(CLIB_STUBS_LST) $(INFOS)


$(WRK)/%.info: $(WRK)/%.o
	od65 --dump-all $< >$@

$(WRK)/oslib/%.info: $(WRK)/oslib/%.o
	od65 --dump-all $< >$@

$(WRK)/%.o: $(RTDIR)/%.s | $(WRK)
	$(AS) $(ASOPT) -o $@ $<

$(WRK)/%.o: $(COMDIR)/%.s | $(WRK)
	$(AS) $(ASOPT) -o $@ $<

$(WRK)/%.o: $(BBCDIR)/%.s | $(WRK)
	$(AS) $(ASOPT) -o $@ $<

$(WRK)/oslib/%.o: $(BBCDIR)/oslib/%.s | $(WRK)/oslib
	$(AS) $(ASOPT) -o $@ $<

$(WRK)/%.o: $(WRK)/%.s
	$(AS) $(ASOPT) -o $@ $<

$(WRK)/%.s: $(RTDIR)/%.c
	$(CC) $(CCOPT) -o $@ $<

$(WRK)/%.s: $(COMDIR)/%.c
	$(CC) $(CCOPT) -o $@ $<

$(WRK)/%.s: $(BBCDIR)/%.c
	$(CC) $(CCOPT) -o $@ $<

$(WRK)/oslib/%.s: $(BBCDIR)/oslib/%.c
	$(CC) $(CCOPT) -o $@ $<

$(WRK)/clib_stubs.s: $(BUILD)/clib.map clib_stubs.pl clib_stubs.py
	$(CLIB_STUBS_SCRIPT) $(BUILD)/clib.map $(WRK)/clib_stubs.s

$(BUILD)/clib.lbl $(BUILD)/clib-mos.lbl: $(BUILD)/clib.map clib_stubs.pl clib_stubs.py
	$(CLIB_STUBS_SCRIPT) $(BUILD)/clib.map $(WRK)/clib_stubs_temp.s $(BUILD)/clib.lbl $(BUILD)/clib-mos.lbl
	@rm -f $(WRK)/clib_stubs_temp.s

$(BUILD)/clib.rom $(BUILD)/clib.map &: $(WRK)/clib_rom.o $(RTOBJS) clib_rom.cfg
	-rm $(BUILD)/clib_rom.tmp.lib
	$(AR) a $(BUILD)/clib_rom.tmp.lib $(shell cat $(CLIB_OBJS_LST))
	$(LD) $(LDOPT) -m $(BUILD)/clib.map -C clib_rom.cfg -o $(BUILD)/clib.rom $(WRK)/clib_rom.o $(BUILD)/clib_rom.tmp.lib

$(BUILD)/clib.lib: $(WRK)/clib_stubs.o $(CLIB_STUBS_LST)
	-rm $(BUILD)/clib.lib >/dev/null
	$(AR) a $@ $(WRK)/clib_stubs.o
	$(AR) a $@ $(shell cat $(CLIB_STUBS_LST))

# Copy manifest files to CC65 project for build integration (loose coupling)
.PHONY: copy-manifests
copy-manifests: $(CLIB_INCS)
	@echo "Checking for CC65 project at $(CC65_SRC)..."
	@if [ -d "$(CC65_SRC)" ]; then \
		echo "Found CC65 source directory: $(CC65_SRC)"; \
		if [ -d "$(CC65_SRC)/libsrc/bbc-clib" ]; then \
			echo "Copying manifest files to CC65 project..."; \
			cp $(WRK)/excluded_functions.manifest $(CC65_SRC)/libsrc/bbc-clib/excluded_functions.manifest 2>/dev/null || echo "Warning: Could not copy excluded_functions.manifest"; \
			cp $(WRK)/rom_functions.manifest $(CC65_SRC)/libsrc/bbc-clib/rom_functions.manifest 2>/dev/null || echo "Warning: Could not copy rom_functions.manifest"; \
			echo "Manifest files updated in CC65 project."; \
		else \
			echo "Warning: $(CC65_SRC)/libsrc/bbc-clib directory not found - manifests not copied"; \
		fi; \
	else \
		echo "Warning: CC65_SRC directory $(CC65_SRC) not found - manifests not copied"; \
		echo "Set CC65_SRC environment variable to your cc65 source directory if needed"; \
	fi
