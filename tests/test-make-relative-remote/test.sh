#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/../common.sh"
source "${SCRIPT_DIR}/../../functions.sh"

setup() {
    rm -rf /workspace/*
    local test_data_dir="${SCRIPT_DIR}/data/repository-${1}/"
    if [[ -d "${test_data_dir}" ]]; then
    # Works like GitHub action, checking out the workspace directory
        cp -r "${test_data_dir}"* /workspace/
    fi
    cd /workspace
}

# Test resulting directory structure from calling make_relative_remote
# Expected output is the directory structure after moving the contents of SRC_PATH to REMOTE_PATH
# e.g. make_relative_remote "/home/user/website" "/var/www/html" should return "/var/www/html/website"
# 1st argument: SRC_PATH, 2nd argument: REMOTE_PATH
# How can I make sure the make test is not caching the docker and creating it fresh
test_make_relative_remote() {
  setup "$1"
  SRC_PATH=$2
  REMOTE_PATH=$3

  echo -e "${GREEN}REMOTE_PATH='$REMOTE_PATH' SRC_PATH='$SRC_PATH'${NC}" 
  make_relative_remote

  # Only compare the expected directory structure if REMOTE_PATH is not empty
  if [[ -n "$REMOTE_PATH" && "$REMOTE_PATH" != "$SRC_PATH" ]]; then
      # Verify that REMOTE_PATH and its folders exist in /workspace
    echo "Verifying that REMOTE_PATH and its folders exist in /workspace"
    if [ -d "/workspace/$REMOTE_PATH" ]; then
        echo -e "${GREEN}REMOTE_PATH exists in /workspace"
    else
        echo -e "${RED}Verification failed: REMOTE_PATH does not exist in /workspace.${NC}"
    fi
  else
    echo -e "${YELLOW}REMOTE_PATH is empty or equal to SRC_PATH, skipping comparison.${NC}"
  fi
}

# Test cases, make remote directory relative to to the tests directory
test_make_relative_remote "1" "." ""
test_make_relative_remote "2" "./wp-content" "./wp-content"
test_make_relative_remote "3" "." "wp-content/"
test_make_relative_remote "4" "." "wp-content/themes/beautiful-pro" 
test_make_relative_remote "5" "my-awesome-plugins" "wp-content/plugins" 
test_make_relative_remote "6" "my-awesome-plugins/blues-brothers" "wp-content/plugins" 