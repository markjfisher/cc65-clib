#!/bin/bash
# Environment variables for soft65c02 unit test harness
# Source this before running tests, or run_unit_tests.sh does it for you.

export CLIB_ROOT="${CLIB_ROOT:-$(pwd)}"
export WS_ROOT="${WS_ROOT:-$CLIB_ROOT}"
export CC65_ROOT="${CC65_ROOT:-${CC65_SRC:-$(realpath "$CLIB_ROOT/../cc65")}}"
export CC65_SRC="${CC65_SRC:-$CC65_ROOT}"
export CC65_HOME="${CC65_HOME:-$CC65_ROOT}"
export UNIT_TEST_DIR=$WS_ROOT/tests/unit
export HARNESS_DIR=$WS_ROOT/tests/harness
export SOFT65C02_BUILD_DIR=$WS_ROOT/build/unit-testing

mkdir -p "$SOFT65C02_BUILD_DIR" > /dev/null 2>&1
