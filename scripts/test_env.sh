#!/bin/bash
# Environment variables for soft65c02 unit test harness
# Source this before running tests, or run_unit_tests.sh does it for you.

export CC65_ROOT=$(realpath ../cc65)
export CLIB_ROOT=$(realpath .)
export WS_ROOT=$(realpath .)
export UNIT_TEST_DIR=$WS_ROOT/tests/unit
export HARNESS_DIR=$WS_ROOT/tests/harness
export SOFT65C02_BUILD_DIR=$WS_ROOT/build/unit-testing

mkdir -p "$SOFT65C02_BUILD_DIR" > /dev/null 2>&1