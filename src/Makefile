BUILD=../build

# CC65 source directory for manifest file copying (loose coupling)
CC65_SRC ?= ../../cc65

# If the bbc and bbc-clib cc65's get merged, may need to add "-D BBC_CLIB" into CCOPT and ASOPT
LD=ld65
LDOPT=-v -vm
CC=cc65
CCOPT=-g -T -O -Or -r -I libsrc/bbc -I libsrc/runtime
AS=ca65
ASOPT=-t bbc
AR=ar65

CLIB_IMPORTS_SCRIPT = python3 clib_imports.py
CLIB_STUBS_SCRIPT = python3 clib_stubs.py

RTDIR=libsrc/runtime
COMDIR=libsrc/common
BBCDIR=libsrc/bbc
RTSRCS=$(wildcard $(RTDIR)/*.s) 
COMSRCS=$(shell find $(COMDIR) -iname "*.s" -o -iname "*.c")
BBCSRCS=$(shell find $(BBCDIR) -iname "*.s" -o -iname "*.c")
SRCSNOP=$(COMSRCS:$(COMDIR)/%=%) $(RTSRCS:$(RTDIR)/%=%) $(BBCSRCS:$(BBCDIR)/%=%)

# $(info RTSRCS: $(RTSRCS))
# $(info COMSRCS: $(COMSRCS))
# $(info BBCSRCS: $(BBCSRCS))
# $(info SRCSNOP: $(SRCSNOP))

WRK=$(BUILD)/libwrk

RESOLVE_OBJS_SCRIPT = python3 resolve_objs.py
EXCLUDED_OBJS_MK    = $(WRK)/excluded_objs.mk

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


.PHONY:clean all copy-cc65-artifacts

all:: $(OBJS) $(BUILD)/clib.rom $(WRK)/clib_stubs.s $(BUILD)/clib.lib $(BUILD)/clib.lbl $(BUILD)/clib-mos.lbl $(EXCLUDED_OBJS_MK) copy-cc65-artifacts | $(WRK) $(WRK)/oslib

clean::
	-rm -r $(WRK) 2>/dev/null
	-rm $(BUILD)/clib.rom 2>/dev/null
	-rm $(BUILD)/clib.lib 2>/dev/null
	-rm $(BUILD)/clib.map 2>/dev/null
	-rm $(BUILD)/clib.lbl 2>/dev/null
	-rm $(BUILD)/clib-mos.lbl 2>/dev/null


$(WRK)/clib_rom.o: clib_rom.s $(CLIB_INCS)
	$(AS) $(ASOPT) -I $(WRK) -o $@ $<

$(CLIB_INCS): $(RTSRCS) clib_imports.py $(WRK) $(OBJS) $(INFOS) 
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

$(WRK)/clib_stubs.s: $(BUILD)/clib.map clib_stubs.py
	$(CLIB_STUBS_SCRIPT) $(BUILD)/clib.map $(WRK)/clib_stubs.s

$(BUILD)/clib.lbl $(BUILD)/clib-mos.lbl: $(BUILD)/clib.map clib_stubs.py
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

$(EXCLUDED_OBJS_MK): resolve_objs.py $(WRK)/excluded_functions.manifest $(INFOS)
	$(RESOLVE_OBJS_SCRIPT) $(WRK) $(WRK)/excluded_functions.manifest > $@


copy-cc65-artifacts: $(CLIB_INCS) $(WRK)/clib_stubs.s $(EXCLUDED_OBJS_MK)
	@echo "Checking for CC65 project at $(CC65_SRC)..."
	@if [ -d "$(CC65_SRC)" ]; then \
		echo "Found CC65 source directory: $(CC65_SRC)"; \
		if [ -d "$(CC65_SRC)/libsrc/bbc-clib" ]; then \
			echo "Copying bbc build artifacts to CC65 project..."; \
			cp $(WRK)/excluded_functions.manifest $(CC65_SRC)/libsrc/bbc-clib/excluded_functions.manifest 2>/dev/null || echo "Warning: Could not copy excluded_functions.manifest"; \
			cp $(WRK)/rom_functions.manifest      $(CC65_SRC)/libsrc/bbc-clib/rom_functions.manifest      2>/dev/null || echo "Warning: Could not copy rom_functions.manifest"; \
			cp $(WRK)/clib_stubs.s                $(CC65_SRC)/libsrc/bbc-clib/clib_stubs.s                2>/dev/null || echo "Warning: Could not copy clib_stubs.s"; \
			cp $(EXCLUDED_OBJS_MK)                $(CC65_SRC)/libsrc/bbc-clib/excluded_objs.mk            2>/dev/null || echo "Warning: Could not copy excluded_objs.mk"; \
			echo "Manifest and stub files updated in CC65 project."; \
		else \
			echo "Warning: $(CC65_SRC)/libsrc/bbc-clib directory not found - artifacts not copied"; \
		fi; \
	else \
		echo "Warning: CC65_SRC directory $(CC65_SRC) not found - manifests not copied"; \
		echo "Set CC65_SRC environment variable to your cc65 source directory if needed"; \
	fi
