BUILD := ../build
WRK   := $(BUILD)/libwrk
OUT   := $(BUILD)

# CC65 source directory for manifest file copying (loose coupling)
CC65_SRC ?= ../../cc65

LD=ld65
LDOPT=-v -vm
CC=cc65
CCOPT=-g -T -O -Or -r -I libsrc/bbc -I libsrc/runtime
AS=ca65
ASOPT=-t bbc
AR=ar65

CLIB_IMPORTS_SCRIPT = python3 clib_imports.py
CLIB_STUBS_SCRIPT   = python3 clib_stubs.py
RESOLVE_OBJS_SCRIPT = python3 resolve_objs.py

RTDIR=libsrc/runtime
COMDIR=libsrc/common
BBCDIR=libsrc/bbc

RTSRCS := $(wildcard $(RTDIR)/*.s)
COMSRCS := $(shell find $(COMDIR) -iname "*.s" -o -iname "*.c")
BBCSRCS := $(shell find $(BBCDIR) -iname "*.s" -o -iname "*.c")
SRCSNOP := $(COMSRCS:$(COMDIR)/%=%) $(RTSRCS:$(RTDIR)/%=%) $(BBCSRCS:$(BBCDIR)/%=%)

# Work products
OBJS  := $(addprefix $(WRK)/, $(patsubst %.c, %.o, $(patsubst %.s,%.o,$(SRCSNOP))))
INFOS := $(patsubst %.o, %.info, $(OBJS))

CLIB_RTIMPORT   := $(OUT)/clib_imports.inc
CLIB_RTJUMPS    := $(OUT)/clib_imports_jmp.inc
CLIB_OBJS_LST   := $(OUT)/clib_include_objs.lst
CLIB_STUBS_LST  := $(OUT)/clib_include_lib_objs.lst
EXCLUDED_OBJS_MK:= $(OUT)/excluded_objs.mk
inc_objs_MK   := $(OUT)/inc_objs.mk
ROM_FUNCS_MAN   := $(OUT)/rom_functions.manifest
EXCL_FUNCS_MAN  := $(OUT)/excluded_functions.manifest

CLIB_STUBS_S    := $(OUT)/clib_stubs.s

$(ROM_FUNCS_MAN) $(EXCL_FUNCS_MAN) $(inc_objs_MK): $(CLIB_INCS)
	@true

CLIB_INCS = $(CLIB_RTIMPORT) $(CLIB_RTJUMPS) $(CLIB_OBJS_LST) $(CLIB_STUBS_LST)

.PHONY: all clean generate copy-cc65-artifacts rom lib

# --------------------------------------------------------------------
# Top-levels
# --------------------------------------------------------------------

# Full pipeline: build objects, ROM image, stubs, lib, labels, and copy to cc65
all: generate copy-cc65-artifacts

generate: $(OBJS) $(INFOS) $(CLIB_INCS) $(EXCLUDED_OBJS_MK) $(CLIB_STUBS_S) $(BUILD)/clib.lbl $(BUILD)/clib-mos.lbl rom lib
	@echo "Artifacts generated in $(WRK):"
	@echo "  - clib_imports.inc / clib_imports_jmp.inc"
	@echo "  - clib_include_objs.lst (ROM lib contents)"
	@echo "  - clib_include_lib_objs.lst (bbc-clib.lib contents)"
	@echo "  - rom_functions.manifest / excluded_functions.manifest"
	@echo "  - inc_objs.mk (definitive basenames for cc65/libsrc bbc-clib)"
	@echo "  - excluded_objs.mk (resolved objs by symbol scan)"
	@echo "  - clib_stubs.s / *.lbl"

# Keep for convenience if you want to build ROM or LIB separately
rom: $(BUILD)/clib.rom
lib: $(BUILD)/clib.lib

clean:
	-rm -r $(WRK) 2>/dev/null
	-rm $(BUILD)/clib.rom 2>/dev/null
	-rm $(BUILD)/clib.lib 2>/dev/null
	-rm $(BUILD)/clib.map 2>/dev/null
	-rm $(BUILD)/clib.lbl 2>/dev/null
	-rm $(BUILD)/clib-mos.lbl 2>/dev/null

# Directory targets
$(BUILD):
	@mkdir -p $@

$(WRK):
	@mkdir -p $@

$(OUT):
	@mkdir -p $@

$(WRK)/oslib:
	@mkdir -p $@


# --------------------------------------------------------------------
# Object / info generation
# --------------------------------------------------------------------

$(WRK)/%.info: $(WRK)/%.o | $(WRK)
	od65 --dump-all $< >$@

$(WRK)/oslib/%.info: $(WRK)/oslib/%.o | $(WRK)
	od65 --dump-all $< >$@

$(WRK)/%.o: $(RTDIR)/%.s | $(WRK)
	$(AS) $(ASOPT) -o $@ $<

$(WRK)/%.o: $(COMDIR)/%.s | $(WRK)
	$(AS) $(ASOPT) -o $@ $<

$(WRK)/%.o: $(BBCDIR)/%.s | $(WRK)
	$(AS) $(ASOPT) -o $@ $<

$(WRK)/oslib/%.o: $(BBCDIR)/oslib/%.s | $(WRK)/oslib
	$(AS) $(ASOPT) -o $@ $<

$(WRK)/%.o: $(WRK)/%.s | $(WRK)
	$(AS) $(ASOPT) -o $@ $<

$(WRK)/%.s: $(RTDIR)/%.c | $(WRK)
	$(CC) $(CCOPT) -o $@ $<

$(WRK)/%.s: $(COMDIR)/%.c | $(WRK)
	$(CC) $(CCOPT) -o $@ $<

$(WRK)/%.s: $(BBCDIR)/%.c | $(WRK)
	$(CC) $(CCOPT) -o $@ $<

$(WRK)/oslib/%.s: $(BBCDIR)/oslib/%.c | $(WRK)/oslib
	$(CC) $(CCOPT) -o $@ $<

$(OUT)/%.o: $(OUT)/%.s | $(OUT)
	$(AS) $(ASOPT) -o $@ $<

# --------------------------------------------------------------------
# Imports / manifests / final list generation
# --------------------------------------------------------------------

# clib_imports.py writes ALL of these files in $(WRK):
#   - clib_imports.inc, clib_imports_jmp.inc
#   - clib_include_objs.lst, clib_include_lib_objs.lst
#   - rom_functions.manifest, excluded_functions.manifest
#   - inc_objs.mk

# One stamp that drives the generator
IMPORTS_STAMP := $(WRK)/clib_imports.stamp

# Every file produced by clib_imports.py
GEN_ARTIFACTS := \
  $(CLIB_RTIMPORT) \
  $(CLIB_RTJUMPS)  \
  $(CLIB_OBJS_LST) \
  $(CLIB_STUBS_LST)\
  $(ROM_FUNCS_MAN) \
  $(EXCL_FUNCS_MAN)\
  $(inc_objs_MK)

# All artifacts are built when the stamp is built
$(GEN_ARTIFACTS): $(IMPORTS_STAMP)

# Build the stamp (runs the script ONCE)
$(IMPORTS_STAMP): $(RTSRCS) clib_imports.py $(OBJS) $(INFOS) | $(WRK) $(OUT)
	$(CLIB_IMPORTS_SCRIPT) \
		$(CLIB_RTIMPORT) $(CLIB_RTJUMPS) \
		$(CLIB_OBJS_LST) $(CLIB_STUBS_LST) \
		--cc65-libsrc $(CC65_SRC)/libsrc \
		--target bbc-clib \
		$(INFOS)
	@touch $@

# Optional: your old resolve pass still supported (consumes excluded_functions.manifest)
$(EXCLUDED_OBJS_MK): resolve_objs.py $(EXCL_FUNCS_MAN) $(INFOS) | $(WRK)
	$(RESOLVE_OBJS_SCRIPT) $(WRK) $(EXCL_FUNCS_MAN) > $@

# --------------------------------------------------------------------
# ROM image and lib build
# --------------------------------------------------------------------

# Assemble the tiny ROM "loader" object that pulls in the jump table
$(WRK)/clib_rom.o: clib_rom.s $(CLIB_INCS) | $(WRK)
	$(AS) $(ASOPT) -I $(WRK) -I $(OUT) -o $@ $<

# Link once via a stamp; this produces BOTH clib.rom and clib.map
CLIB_LINK_STAMP := $(WRK)/clib_link.stamp

$(CLIB_LINK_STAMP): $(WRK)/clib_rom.o clib_rom.cfg $(CLIB_OBJS_LST) | $(BUILD)
	-rm -f $(BUILD)/clib_rom.tmp.lib
	$(AR) a $(BUILD)/clib_rom.tmp.lib $(shell cat $(CLIB_OBJS_LST))
	$(LD) $(LDOPT) -m $(BUILD)/clib.map -C clib_rom.cfg \
		-o $(BUILD)/clib.rom $(WRK)/clib_rom.o $(BUILD)/clib_rom.tmp.lib
	@touch $@

# Both outputs are considered up-to-date when the stamp is updated
$(BUILD)/clib.rom $(BUILD)/clib.map: $(CLIB_LINK_STAMP)

# Generate assembler stubs from the ROM map
$(CLIB_STUBS_S): $(BUILD)/clib.map clib_stubs.py | $(OUT)
	$(CLIB_STUBS_SCRIPT) $(BUILD)/clib.map $(CLIB_STUBS_S)

# Generate VICE label files from the ROM map
$(BUILD)/clib.lbl $(BUILD)/clib-mos.lbl: $(BUILD)/clib.map clib_stubs.py | $(BUILD)
	$(CLIB_STUBS_SCRIPT) $(BUILD)/clib.map $(WRK)/clib_stubs_temp.s $(BUILD)/clib.lbl $(BUILD)/clib-mos.lbl
	@rm -f $(WRK)/clib_stubs_temp.s

# Build the companion static library that holds non-ROM objects + the stubs
$(BUILD)/clib.lib: $(OUT)/clib_stubs.o $(CLIB_STUBS_LST) | $(BUILD)
	-rm -f $(BUILD)/clib.lib
	$(AR) a $@ $(OUT)/clib_stubs.o
	$(AR) a $@ $(shell cat $(CLIB_STUBS_LST))

# --------------------------------------------------------------------
# Copy artifacts to cc65 (depends on generate)
# --------------------------------------------------------------------

copy-cc65-artifacts: generate
	@echo "Checking for CC65 project at $(CC65_SRC)..."
	@if [ -d "$(CC65_SRC)" ]; then \
		echo "Found CC65 source directory: $(CC65_SRC)"; \
		if [ -d "$(CC65_SRC)/libsrc/bbc-clib" ]; then \
			echo "Copying bbc build artifacts to CC65 project..."; \
			cp $(CLIB_STUBS_S)      $(CC65_SRC)/libsrc/bbc-clib/clib_stubs.s   2>/dev/null || echo "Warning: Could not copy clib_stubs.s"; \
			cp $(OUT)/inc_objs.mk   $(CC65_SRC)/libsrc/bbc-clib/inc_objs.mk  2>/dev/null || echo "Warning: Could not copy inc_objs.mk"; \
			echo "Artifacts updated in CC65 project."; \
		else \
			echo "Warning: $(CC65_SRC)/libsrc/bbc-clib directory not found - artifacts not copied"; \
		fi; \
	else \
		echo "Warning: CC65_SRC directory $(CC65_SRC) not found - artifacts not copied"; \
		echo "Set CC65_SRC to your cc65 source directory if needed"; \
	fi
