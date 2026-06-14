#
# Top-level Makefile for cc65-clib
#
# Delegates to src/ for building the ROM and to build-rom/ for the full
# cc65 integration build pipeline.
#
# Typical workflow:
#   make           # build the CLIB ROM + copy artifacts to cc65
#   make test      # run the full test suite (unit + integration)
#   make clean     # clean ROM, libraries, and build artifacts

.PHONY: all rom lib clean test

all: rom

rom:
	$(MAKE) -C src

lib:
	$(MAKE) -C src lib

clean:
	$(MAKE) -C src clean

# Full rebuild: ROM + cc65 libraries + all tests
test:
	./run_tests.sh