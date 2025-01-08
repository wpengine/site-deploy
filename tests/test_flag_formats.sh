#!/bin/bash

# Demonstrates the different ways to pass flags to rsync.
# 
# When determining the correct way to pass flags to rsync, it is helpful to
# understand how the shell interprets quotes and whitespace. This script runs
# in debug mode to show how the shell interprets the flags for each test case.
#
# This is a stand-alone script. It is only meant for demonstration and does not
# directly test code in this project.

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/helpers/common.sh"

set -x

FLAGS="-avzr --filter=':- .gitignore' --exclude='.*'"
FLAGS_ARRAY=("-avzr" "--filter=:- .gitignore" "--exclude='.*'")

test_flags_no_quotes() {
  rsync $FLAGS --dry-run "$SCRIPT_DIR"/data . > /dev/null
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}test_flags_no_quotes: Success${NC}"
  else
    echo -e "${RED}test_flags_no_quotes: Failure${NC}"
  fi
}

test_flags_double_quotes() {
  rsync "$FLAGS" --dry-run "$SCRIPT_DIR"/data . > /dev/null
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}test_flags_double_quotes: Success${NC}"
  else
    echo -e "${RED}test_flags_double_quotes: Failure${NC}"
  fi
}

test_flags_array() {
  rsync "${FLAGS_ARRAY[@]}" --dry-run "$SCRIPT_DIR"/data . > /dev/null
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}test_flags_array: Success${NC}"
  else
    echo -e "${RED}test_flags_array: Failure${NC}"
  fi
}

main() {
  test_flags_no_quotes
  test_flags_double_quotes
  test_flags_array
}

main
