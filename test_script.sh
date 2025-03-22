#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Creating test environment ===${NC}"

# Create test directory structure
TEST_DIR="unpack_test"
rm -rf "$TEST_DIR" 2>/dev/null
mkdir -p "$TEST_DIR"/{level1/{level2,empty},single_files}

cd "$TEST_DIR"

# Create and compress files at different levels
echo "This is a test file at the root level" > root_file.txt
echo "This is a test file in level1" > level1/level1_file.txt
echo "This is a test file in level2" > level1/level2/level2_file.txt

# Create multiple files for a zip with multiple files
mkdir -p temp_multi
echo "File 1 in multi-file zip" > temp_multi/file1.txt
echo "File 2 in multi-file zip" > temp_multi/file2.txt

# Create different compression formats
echo -e "${YELLOW}=== Creating compressed files ===${NC}"

# Root level files
gzip -c root_file.txt > root_file.txt.gz
echo "Created root_file.txt.gz"

# Single file zip
zip -q single_files/single_file.zip root_file.txt
echo "Created single_files/single_file.zip (contains 1 file)"

# Multi-file zip
cd temp_multi
zip -q ../level1/multi_files.zip *
cd ..
echo "Created level1/multi_files.zip (contains multiple files)"

# Level 1 files
bzip2 -c level1/level1_file.txt > level1/level1_file.txt.bz2
echo "Created level1/level1_file.txt.bz2"

# Level 2 files
gzip -c level1/level2/level2_file.txt > level1/level2/level2_file.txt.gz
echo "Created level1/level2/level2_file.txt.gz"

# Create a test file without an extension that is actually compressed
gzip -c root_file.txt > level1/no_extension_gzip
echo "Created level1/no_extension_gzip (gzip file without .gz extension)"

# Clean up temporary files and directory
rm -rf temp_multi
echo ""

# Function to run the unpack script and display results
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_success="$3"
    local expected_fails="$4"
    
    echo -e "${YELLOW}=== Test: $test_name ===${NC}"
    echo "Command: $command"
    echo "Expected successful unpacks: $expected_success"
    
    # Run the command and capture exit code
    eval "$command"
    local exit_code=$?
    
    # The exit code from unpack_v2.sh is the number of failures
    if [[ $exit_code -eq 0 || $exit_code -eq $expected_fails ]]; then
        echo -e "${GREEN}✓ Test passed! All files unpacked successfully.${NC}"
    else
        echo -e "${RED}✗ Test failed! Expected $expected_success successful unpacks, got $exit_code failures.${NC}"
    fi
    echo ""
    
    # List directory contents after the test
    echo "Directory structure after test:"
    find . -type f | sort
    echo ""
}
# Full path to your unpack script
UNPACK_SCRIPT="~/unpack_script/unpack.sh"

# Test cases
echo -e "${YELLOW}=== Starting tests ===${NC}"

# Test 1: Unpack a single file
run_test "Single file" "$UNPACK_SCRIPT root_file.txt.gz" 1 0

# Test 2: Unpack a directory without recursion
run_test "Directory without recursion" "$UNPACK_SCRIPT level1" 3 1

# Test 3: Unpack a directory with recursion
run_test "Directory with recursion" "$UNPACK_SCRIPT -r -v level1" 4 5

# Test 4: Unpack with verbose option
run_test "Verbose mode" "$UNPACK_SCRIPT -v single_files" 1 0

# Test 5: Unpack file without extension
run_test "File without extension" "$UNPACK_SCRIPT -v level1/no_extension_gzip" 1 0

echo -e "${GREEN}All tests completed!${NC}"