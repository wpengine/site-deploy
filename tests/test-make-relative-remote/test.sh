#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/../common.sh"
source "${SCRIPT_DIR}/../../functions.sh"
source "${SCRIPT_DIR}/../../entrypoint.sh"

setup() {
    rm -rf /workspace/*
    local test_data_dir="${SCRIPT_DIR}/data/repository-${1}/"
    if [[ -d "${test_data_dir}" ]]; then
    # Works like GitHub action, checking out the workspace directory
        cp -r "${test_data_dir}"* /workspace/
    fi
    ssh-keygen -t rsa -b 2048 -f /workspace/mock_ssh_key -N ""
    chmod 600 /workspace/mock_ssh_key
    
    cd /workspace
}

# Test resulting directory structure from calling sync_files
test_sync_files() {
  setup "$1"
  SRC_PATH=$2
  REMOTE_PATH=$3

  WPE_SSHG_KEY_PRIVATE=$(cat /workspace/mock_ssh_key)

  echo -e "${GREEN}REMOTE_PATH='$REMOTE_PATH' SRC_PATH='$SRC_PATH'${NC}" 
  
  # Assign flag values to FLAGS_ARRAY
  FLAGS_ARRAY=("-azvr" "--dry-run" "--inplace" "--exclude='.*'")
  
  # Print the flags for debugging
  echo "Using the following rsync flags:"
  for flag in "${FLAGS_ARRAY[@]}"; do
    echo "$flag"
  done

  sync_files

  # Only compare the expected directory structure if REMOTE_PATH is not empty and REMOTE_PATH is not equal to SRC_PATH
  if [[ -n "$REMOTE_PATH" && "$REMOTE_PATH" != "$SRC_PATH" ]]; then
    # Verify that REMOTE_PATH and its folders exist in /workspace
    if [ -d "/workspace/$REMOTE_PATH" ]; then
        echo -e "${GREEN}REMOTE_PATH exists in /workspace${NC}"
        
        # Compare the contents of the moved REMOTE_PATH to the corresponding files in the data directory
        EXPECTED_PATH="${SCRIPT_DIR}/data/repository-${1}/$SRC_PATH"
        diff -r "/workspace/$REMOTE_PATH" "$EXPECTED_PATH"
        
        # Check the result of the diff command
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Verification failed: expected structure does not match.${NC}"
        else
            echo -e "${GREEN}Verification passed: expected structure matches.${NC}"
        fi
    else
        echo -e "${RED}Verification failed: REMOTE_PATH does not exist in /workspace.${NC}"
    fi
  else
    echo -e "${YELLOW}REMOTE_PATH is empty or equal to SRC_PATH, skipping comparison.${NC}"
  fi
}

# Test cases, make remote directory relative to to the tests directory
#test_sync_files "1" "." ""
#test_sync_files "2" "./wp-content" "./wp-content"
#test_sync_files "3" "." "wp-content/"
#test_sync_files "4" "." "wp-content/themes/beautiful-pro" 
#test_sync_files "5" "my-awesome-plugins" "wp-content/plugins" 
#test_sync_files "6" "my-awesome-plugins/blues-brothers" "wp-content/plugins"
