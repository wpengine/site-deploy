#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/log_debug.sh"
source "${SCRIPT_DIR}/print_mount_paths.sh"
source "${SCRIPT_DIR}/generate_path_excludes.sh"

test_rsync_with_excludes() {
  export SRC_PATH=$1 REMOTE_PATH=$2
  # shellcheck disable=SC2206
  local FLAGS=($3)

  # Generate the exclusion lists before using the output with rsync
  local source_exclude_from; source_exclude_from="$(generate_source_exclude_from)"
  local remote_excludes; remote_excludes="$(generate_remote_excludes)"

  # Capture the output of the rsync command
  output=$(rsync --dry-run -azvr --inplace --exclude='.*' "${FLAGS[@]}" \
                 --exclude-from=<(echo "$source_exclude_from") \
                 --rsync-path="rsync $remote_excludes" \
                 "$SRC_PATH" "$REPO_PATH/tests/fixtures/remote/$REMOTE_PATH")

  if [[ "$SRC_PATH" != *mu-plugins?(/) && "$(pwd)" != *mu-plugins ]]; then
    # Fail if the output is missing the expected file
    if ! echo "$output" | grep -q "test-plugin.php"; then
      echo -e "${RED}Test failed for pwd='$(pwd)', SRC_PATH='$SRC_PATH', REMOTE_PATH='$REMOTE_PATH': test-plugin.php excluded${NC}"
      echo -e "${BLUE}$(log_debug "Rsync output:" "$output")\n${NC}"
      echo -e "${BLUE}$(log_debug "Source exclude from:" "$source_exclude_from")\n${NC}"
      echo -e "${BLUE}$(log_debug "Remote excludes:" "$remote_excludes")\n${NC}"
      exit 1
    fi

    # Fail if the output is missing the nested plugin file that is excluded at a different path
    if ! echo "$output" | grep -q "cache/object-cache"; then
      echo -e "${RED}Test failed for pwd='$(pwd)', SRC_PATH='$SRC_PATH', REMOTE_PATH='$REMOTE_PATH': cache/object-cache.php excluded${NC}"
      echo -e "${BLUE}$(log_debug "Rsync output:" "$output")\n${NC}"
      echo -e "${BLUE}$(log_debug "Source exclude from:" "$source_exclude_from")\n${NC}"
      echo -e "${BLUE}$(log_debug "Remote excludes:" "$remote_excludes")\n${NC}"
      exit 1
    fi
  fi

  # Fail if the output contains the excluded mu-plugin file
  if echo "$output" | grep -q "mu-plugin.php"; then
    echo -e "${RED}Test failed for pwd='$(pwd)', SRC_PATH='$SRC_PATH', REMOTE_PATH='$REMOTE_PATH': WPE mu-plugin.php included${NC}"
    echo -e "${BLUE}$(log_debug "Rsync output:" "$output")\n${NC}"
    echo -e "${BLUE}$(log_debug "Source exclude from:" "$source_exclude_from")\n${NC}"
    echo -e "${BLUE}$(log_debug "Remote excludes:" "$remote_excludes")\n${NC}"
    exit 1
  fi
}

main() {
  read -r mounted_src_path base_mount_path <<< "$(print_mount_paths "/site")"
  echo -e "${BLUE}Info: mounted_src_path='$mounted_src_path', base_mount_path='$base_mount_path', pwd='$(pwd)'${NC}"

  local test_cases=(
    # SRC_PATH            REMOTE_PATH
    "."                   ""
    "."                   "wp-content"
    "."                   "wp-content/" # Trailing slash in REMOTE_PATH
    "."                   "wp-content/plugins"
    "."                   "wp-content/plugins/" # Trailing slash in REMOTE_PATH
    "."                   "wp-content/mu-plugins"
    "."                   "wp-content/mu-plugins/" # Trailing slash in REMOTE_PATH
  )

  if [[ "$mounted_src_path" == *src && "$(pwd)" == *site ]]; then
    test_cases+=(
      "wp-content"          ""
      "wp-content"          "wp-content"
      "wp-content"          "wp-content/" # Trailing slash in REMOTE_PATH
      "wp-content/"         ""
      "wp-content/"         "wp-content"
      "wp-content/"         "wp-content/" # Trailing slash in REMOTE_PATH
      "wp-content/plugins"  ""
      "wp-content/plugins"  "wp-content/plugins"
      "wp-content/plugins"  "wp-content/plugins/" # Trailing slash in REMOTE_PATH
      "wp-content/plugins/" "wp-content/plugins"
      "wp-content/plugins/" "wp-content/plugins/" # Trailing slash in REMOTE_PATH
      "wp-content/mu-plugins"  ""
      "wp-content/mu-plugins"  "wp-content"
#      "wp-content/mu-plugins"  "wp-content/mu-plugins"
#      "wp-content/mu-plugins"  "wp-content/mu-plugins/" # Trailing slash in REMOTE_PATH
#      "wp-content/mu-plugins/" "wp-content/mu-plugins"
#      "wp-content/mu-plugins/" "wp-content/mu-plugins/" # Trailing slash in REMOTE_PATH
#      "wp-content/mu-plugins"  ""
#      "wp-content/mu-plugins"  "wp-content"
#      "wp-content/mu-plugins"  "wp-content/mu-plugins"
#      "wp-content/mu-plugins"  "wp-content/mu-plugins/" # Trailing slash in REMOTE_PATH
#      "wp-content/mu-plugins/" "wp-content"
#      "wp-content/mu-plugins/" "wp-content/mu-plugins"
#      "wp-content/mu-plugins/" "wp-content/mu-plugins/" # Trailing slash in REMOTE_PATH
    )
  fi

  if [[ "$mounted_src_path" == *wp-content && "$(pwd)" == *site ]]; then
    test_cases+=(
      "plugins"  ""
      "plugins" "wp-content/plugins"
      "plugins" "wp-content/plugins/" # Trailing slash in REMOTE_PATH
      "plugins/" "wp-content/plugins"
      "plugins/" "wp-content/plugins/" # Trailing slash in REMOTE_PATH
      "mu-plugins"  ""
#      "mu-plugins"  "wp-content/mu-plugins"
#      "mu-plugins"  "wp-content/mu-plugins/" # Trailing slash in REMOTE_PATH
#      "mu-plugins/" "wp-content/mu-plugins"
#      "mu-plugins/" "wp-content/mu-plugins/" # Trailing slash in REMOTE_PATH
    )
  fi

  for ((i=0; i<${#test_cases[@]}; i+=2)); do
    echo -e "${BLUE}Generating rsync excludes for SRC_PATH='${test_cases[i]}', REMOTE_PATH='${test_cases[i+1]}'${NC}"
    test_rsync_with_excludes "${test_cases[i]}" "${test_cases[i+1]}"
  done

  local flags=("--delete")
  for ((i=0; i<${#test_cases[@]}; i+=2)); do
    echo -e "${BLUE}Generating rsync excludes with flags='${flags[*]}' for SRC_PATH='${test_cases[i]}', REMOTE_PATH='${test_cases[i+1]}'${NC}"
    test_rsync_with_excludes "${test_cases[i]}" "${test_cases[i+1]}" "${flags[@]}"
  done

  echo -e "${GREEN}Tests passed for mounted_src_path='$mounted_src_path', base_mount_path='$base_mount_path', pwd='$(pwd)'${NC}"
}

main
