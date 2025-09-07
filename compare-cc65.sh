#!/bin/bash

# Script to compare cc65/libsrc/bbc/ and cc65-clib/src/libsrc/bbc/ directories
# Usage: ./compare-cc65.sh [options]
# 
# Options (to be implemented):
#   -s, --sync     Synchronize directories (copy missing/different files)
#   -v, --verbose  Verbose output
#   -h, --help     Show this help

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directory paths
CC65_DIR="/home/markf/dev/bbc/cc65/libsrc/bbc"
CC65_CLIB_DIR="/home/markf/dev/bbc/cc65-clib/src/libsrc/bbc"

# Temporary files for storing file lists
TEMP_DIR=$(mktemp -d)
CC65_FILES="$TEMP_DIR/cc65_files.txt"
CC65_CLIB_FILES="$TEMP_DIR/cc65_clib_files.txt"
COMMON_FILES="$TEMP_DIR/common_files.txt"
ONLY_CC65="$TEMP_DIR/only_cc65.txt"
ONLY_CC65_CLIB="$TEMP_DIR/only_cc65_clib.txt"

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Function to print colored output
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_diff() {
    echo -e "${RED}$1${NC}"
}

print_only() {
    echo -e "${GREEN}$1${NC}"
}

print_common() {
    echo -e "${YELLOW}$1${NC}"
}

# Function to get relative file paths recursively
get_file_list() {
    local dir="$1"
    local output="$2"
    
    if [[ -d "$dir" ]]; then
        find "$dir" -type f | sed "s|^$dir/||" | sort > "$output"
    else
        touch "$output"
    fi
}

# Function to compare two files
compare_files() {
    local file1="$1"
    local file2="$2"
    
    if [[ ! -f "$file1" ]]; then
        return 1
    fi
    
    if [[ ! -f "$file2" ]]; then
        return 1
    fi
    
    # Use diff to compare files, return 0 if identical, 1 if different
    # We need to handle the exit code properly since diff returns 1 for different files
    if diff -q "$file1" "$file2" >/dev/null 2>&1; then
        return 0  # Files are identical
    else
        local diff_exit_code=$?
        if [[ $diff_exit_code -eq 1 ]]; then
            return 1  # Files are different
        else
            return 2  # Error occurred
        fi
    fi
}

# Main comparison function
main() {
    print_header "Directory Comparison Analysis"
    echo "Source: $CC65_DIR"
    echo "Target: $CC65_CLIB_DIR"
    echo
    
    # Check if directories exist
    if [[ ! -d "$CC65_DIR" ]]; then
        echo "Error: Source directory $CC65_DIR does not exist"
        exit 1
    fi
    
    if [[ ! -d "$CC65_CLIB_DIR" ]]; then
        echo "Error: Target directory $CC65_CLIB_DIR does not exist"
        exit 1
    fi
    
    # Get file lists
    print_header "Collecting file lists..."
    get_file_list "$CC65_DIR" "$CC65_FILES"
    get_file_list "$CC65_CLIB_DIR" "$CC65_CLIB_FILES"
    
    # Find common files
    comm -12 "$CC65_FILES" "$CC65_CLIB_FILES" > "$COMMON_FILES"
    
    # Find files only in cc65
    comm -23 "$CC65_FILES" "$CC65_CLIB_FILES" > "$ONLY_CC65"
    
    # Find files only in cc65-clib
    comm -13 "$CC65_FILES" "$CC65_CLIB_FILES" > "$ONLY_CC65_CLIB"
    
    # Report statistics
    local cc65_count=$(wc -l < "$CC65_FILES")
    local cc65_clib_count=$(wc -l < "$CC65_CLIB_FILES")
    local common_count=$(wc -l < "$COMMON_FILES")
    local only_cc65_count=$(wc -l < "$ONLY_CC65")
    local only_cc65_clib_count=$(wc -l < "$ONLY_CC65_CLIB")
    
    print_header "Summary Statistics"
    echo "Files in cc65:           $cc65_count"
    echo "Files in cc65-clib:      $cc65_clib_count"
    echo "Common files:            $common_count"
    echo "Only in cc65:            $only_cc65_count"
    echo "Only in cc65-clib:       $only_cc65_clib_count"
    echo
    
    # Report files only in cc65
    if [[ $only_cc65_count -gt 0 ]]; then
        print_header "Files only in cc65/libsrc/bbc/"
        while IFS= read -r file; do
            print_only "  + $file"
        done < "$ONLY_CC65"
        echo
    fi
    
    # Report files only in cc65-clib
    if [[ $only_cc65_clib_count -gt 0 ]]; then
        print_header "Files only in cc65-clib/src/libsrc/bbc/"
        while IFS= read -r file; do
            print_only "  + $file"
        done < "$ONLY_CC65_CLIB"
        echo
    fi
    
    # Compare common files
    if [[ $common_count -gt 0 ]]; then
        print_header "Comparing common files..."
        local different_count=0
        local identical_count=0
        
        while IFS= read -r file; do
            local cc65_file="$CC65_DIR/$file"
            local cc65_clib_file="$CC65_CLIB_DIR/$file"
            
            if compare_files "$cc65_file" "$cc65_clib_file"; then
                ((++identical_count))
            else
                ((++different_count))
                print_diff "  ≠ $file (different)"
            fi
        done < "$COMMON_FILES"
        
        echo
        echo "Identical files: $identical_count"
        echo "Different files: $different_count"
        echo
        
        # Show detailed differences for different files
        if [[ $different_count -gt 0 ]]; then
            print_header "Detailed differences"
            while IFS= read -r file; do
                local cc65_file="$CC65_DIR/$file"
                local cc65_clib_file="$CC65_CLIB_DIR/$file"
                
                if ! compare_files "$cc65_file" "$cc65_clib_file"; then
                    echo
                    print_common "File: $file"
                    echo "--- cc65/libsrc/bbc/$file"
                    echo "+++ cc65-clib/src/libsrc/bbc/$file"
                    diff -u "$cc65_file" "$cc65_clib_file" || true
                fi
            done < "$COMMON_FILES"
        fi
    fi
    
    print_header "Analysis Complete"
}

# Parse command line arguments (basic implementation)
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Usage: $0 [options]"
            echo
            echo "Options:"
            echo "  -s, --sync     Synchronize directories (copy missing/different files)"
            echo "  -v, --verbose  Verbose output"
            echo "  -h, --help     Show this help"
            echo
            echo "This script compares cc65/libsrc/bbc/ and cc65-clib/src/libsrc/bbc/ directories"
            echo "and reports differences between them."
            exit 0
            ;;
        -s|--sync)
            echo "Sync functionality not yet implemented"
            exit 1
            ;;
        -v|--verbose)
            echo "Verbose mode not yet implemented"
            exit 1
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
    shift
done

# Run main function
main
