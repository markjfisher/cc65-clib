#
# Build ROM from cc65-clib project and copy to local roms/ directory
#
# This Makefile is now part of the cc65-clib project (consolidated) and
# orchestrates the full build/test cycle:
#   1. Rebuild the CLIB ROM from src/
#   2. Copy generated stubs/manifests into cc65
#   3. Rebuild cc65's bbc and bbc-clib production libraries
#   4. Optionally copy the ROM to an emulator's ROM folder
#
# Paths are relative to the project root (one level up from this Makefile).

# Paths are relative to this Makefile's directory (build-rom/).
# From build-rom/: ../../cc65 = project-sibling cc65 checkout.
CC65_ROOT ?= ../../cc65
ROM_PATH ?= roms
BUILD_DIR ?= build
TARGET_ROM_COPY ?=

.PHONY: all clean rebuild-clib rebuild-clib-rom rebuild-cc65-lib

all: rebuild-clib

# Order matters: the cc65 bbc-clib library links against the generated
# clib_stubs.s / inc_objs.mk, so the ROM + metadata must be (re)generated and
# copied into cc65 *before* the cc65 libraries are built.
rebuild-clib: rebuild-clib-rom rebuild-cc65-lib

rebuild-clib-rom:
	@echo "Cleaning and rebuilding cc65-clib ROM..."
	cd ../src && $(MAKE) clean copy-cc65-artifacts
	@echo "ROM build complete - manifest files generated, and copied to cc65"
	@echo "Copying ROM and VICE symbol files to project roms directory..."
	mkdir -p $(ROM_PATH)
	cp ../build/clib.rom $(ROM_PATH)/clib.rom
	cp ../build/clib.lbl $(ROM_PATH)/clib.lbl
	cp ../build/clib.lib $(ROM_PATH)/clib.lib
	cp ../build/clib-mos.lbl $(ROM_PATH)/clib-mos.lbl
	@if [ -n "$(TARGET_ROM_COPY)" ]; then \
	  echo "Copying ROM and symbol files to emulator roms directory $(TARGET_ROM_COPY)..."; \
	  mkdir -p "$(TARGET_ROM_COPY)"; \
	  cp ../build/clib.rom "$(TARGET_ROM_COPY)/clib.rom"; \
	  cp ../build/clib.lbl "$(TARGET_ROM_COPY)/clib.lbl"; \
	  cp ../build/clib.lib "$(TARGET_ROM_COPY)/clib.lib"; \
	  cp ../build/clib-mos.lbl "$(TARGET_ROM_COPY)/clib-mos.lbl"; \
	else \
	  echo "TARGET_ROM_COPY not set - skipping emulator ROM copy."; \
	fi

rebuild-cc65-lib:
	@echo "Building cc65 bbc, bbc-clib targets"
	cd $(CC65_ROOT) && $(MAKE) -C libsrc TARGETS=bbc
	cd $(CC65_ROOT) && $(MAKE) -C libsrc TARGETS=bbc-clib

clean:
	-rm $(CC65_ROOT)/lib/bbc.lib
	-rm $(CC65_ROOT)/lib/bbc-clib.lib
	cd ../src && $(MAKE) clean
	-rm -f $(ROM_PATH)/clib*
	@if [ -n "$(TARGET_ROM_COPY)" ]; then rm -f "$(TARGET_ROM_COPY)"/clib*; fi
	-rm -rf $(CC65_ROOT)/libwrk/bbc
	-rm -rf $(CC65_ROOT)/libwrk/bbc-clib