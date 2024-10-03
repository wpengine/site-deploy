#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/../common.sh"
source "${SCRIPT_DIR}/../../functions.sh"

setup() {
    rm -rf /workspace/*
    local test_data_dir="${SCRIPT_DIR}/data/repository-${1}/"
    if [[ -d "${test_data_dir}" ]]; then
        cp -r "${test_data_dir}"* /workspace/
    fi
    cd /workspace
}

# Test resulting directory structure from calling make_relative_remote
# Expected output is the directory structure after moving the contents of SRC_PATH to REMOTE_PATH
# e.g. make_relative_remote "/home/user/website" "/var/www/html" should return "/var/www/html/website"
# 1st argument: SRC_PATH, 2nd argument: REMOTE_PATH, 3rd argument: EXPECTED_REMOTE_PATH
test_make_relative_remote() {
  setup "$1"
  SRC_PATH=$2
  REMOTE_PATH=$3
  EXPECTED_REMOTE_PATH=$4

  echo -e "${GREEN}REMOTE_PATH='$REMOTE_PATH' SRC_PATH='$SRC_PATH' EXPECTED_REMOTE_PATH='$EXPECTED_REMOTE_PATH'" 
  # Should I cd into the test_dir?
  make_relative_remote

  if [[ "$REMOTE_PATH" != "$EXPECTED_REMOTE_PATH" ]]; then
      echo -e "${RED}Test failed for SRC_PATH='$SRC_PATH' and REMOTE_PATH='$REMOTE_PATH': expected '$EXPECTED_REMOTE_PATH', got '$REMOTE_PATH'.${NC}"
      return
  fi
}

# Test cases, make remote directory relative to to the tests directory
test_make_relative_remote "1" "." "" ""
test_make_relative_remote "2" "./wp-content" "./wp-content" "./wp-content"
# Ok, I think I am still not understanding how to use make relative remote. I need to test the following scenarios:
# Need to walk through the actual scenerio seen, with the source being .
# REMOTE_PATH=/wp-content
#SRC_PATH=.
#remote = ./wp-content
#source (where I am at locally)= . (current folder), and aim is to make sure excludes goes from the base wp-content/uploads/
# but can't test this... because it will start with top-level folder
test_make_relative_remote "3" "." "wp-content/" "wp-content/"
#test_make_relative_remote "./test_dir/remote/wp-content" ".test_dir/local/wp-content" "./test_dir/remote/wp-content"

# Just deploying out wp-content, need to make sure the resulting folder structure matched expected excludes layout. But what is the difference?
# REMOTE_PATH=/wp-content
# SRC_PATH=.
# EXPECTED_REMOTE_PATH= create wp-content, copy all contents of wp-content into it

# Default: No movement happens
# REMOTE_PATH=
# SRC_PATH=.
# EXPECTED_REMOTE_PATH= nothing changed

# Individual theme, need to make sure resulting folder structure matches expected excludes
# REMOTE_PATH=/wp-content/themes/beautiful-pro
# SRC_PATH=.
# EXPECTED_REMOTE_PATH=create wp-content/themes/beautiful-pro, copy all contents of beautiful-pro into the folder.
