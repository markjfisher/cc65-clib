BUILD_DIR = ../../build
TEST_BUILD_DIR = $(BUILD_DIR)/test-serial
CC_TARGET = bbc
CC_ARGS = -Osir

all: test-disk

$(TEST_BUILD_DIR):
	mkdir -p $(TEST_BUILD_DIR)

# $(TEST_BUILD_DIR)/test: test.c osbyte.s $(TEST_BUILD_DIR)
# 	cl65 $(CC_ARGS) -t $(CC_TARGET) -Ln $(TEST_BUILD_DIR)/test.lbl --mapfile $(TEST_BUILD_DIR)/test.map --start-addr 0x1900 -o $(TEST_BUILD_DIR)/test test.c osbyte.s

$(TEST_BUILD_DIR)/test: test.c osbyte.s $(TEST_BUILD_DIR)
	cl65 $(CC_ARGS) -t $(CC_TARGET) \
	     -Ln $(TEST_BUILD_DIR)/test.lbl \
	     --mapfile $(TEST_BUILD_DIR)/test.map \
	     --start-addr 0x1900 \
	     -o $(TEST_BUILD_DIR)/test \
	     test.c osbyte.s

test-disk: $(TEST_BUILD_DIR)/test
	@echo "Creating test disk..."
	dfstool make --output $(TEST_BUILD_DIR)/test.ssd --overwrite test.json
	@echo "Files ready:"
	@echo "  Disk: $$(realpath $(TEST_BUILD_DIR)/test.ssd)"

clean:
	rm -rf $(TEST_BUILD_DIR)

.PHONY: all test-disk clean
