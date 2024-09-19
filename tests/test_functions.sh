#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/../functions.sh"

# # First argument represents the value of the FLAGS variable.
# # The rest of the arguments represent the expected values of the FLAGS_ARRAY.
# #
# # usage: test_parse_flags <FLAGS> <EXPECTED_FLAGS...>
# test_parse_flags() {
#   local test_case=$1
#   shift
#   local expected_args=("$@")

#   parse_flags "$test_case"

#   local actual_count="${#FLAGS_ARRAY[@]}"
#   local expected_count="${#expected_args[@]}"

#   if [[ "$actual_count" -ne "$expected_count" ]]; then
#     echo -e "${RED}Test failed for FLAGS='$test_case': expected $expected_count arguments, got $actual_count."
#     echo -e "\tActual arguments: ${FLAGS_ARRAY[*]}${NC}"
#     return
#   fi

#   for i in "${!expected_args[@]}"; do
#     if [[ "${FLAGS_ARRAY[$i]}" != "${expected_args[$i]}" ]]; then
#       echo -e "${RED}Test failed for FLAGS='$test_case': expected '${expected_args[$i]}', got '${FLAGS_ARRAY[$i]}'.${NC}"
#       return
#     fi
#   done

#   echo -e "${GREEN}Test passed for FLAGS=\"$test_case\".${NC}"
# }

# # Test cases
# test_parse_flags \
#   "-azvr --inplace --exclude='.*'" \
#   "-azvr" \
#   "--inplace" \
#   "--exclude=.*"

# test_parse_flags \
#   '-azvr --inplace --exclude=".*"' \
#   "-azvr" \
#   "--inplace" \
#   "--exclude=.*"

# test_parse_flags \
#   "-azvr --filter=':- .gitignore' --exclude='.*'" \
#   "-azvr" \
#   "--filter=:- .gitignore" \
#   "--exclude=.*"

# test_parse_flags \
#   "-avzr --delete --filter='P /wp-uploads/**'" \
#   "-avzr" \
#   "--delete" \
#   "--filter=P /wp-uploads/**"

# test_parse_flags \
#   "-avzr --delete --exclude='\$dollar'" \
#   "-avzr" \
#   "--delete" \
#   "--exclude=\$dollar"

# test_parse_flags \
#   "-avzr --exclude='\`back-ticks\`'" \
#   "-avzr" \
#   "--exclude=\`back-ticks\`"

# test_parse_flags \
#   "-avzr --exclude='path\\with\\backslash'" \
#   "-avzr" \
#   "--exclude=path\\with\\backslash"

# Test resulting directory structure from calling make_relative_remote
# Expected output is the directory structure after moving the contents of SRC_PATH to REMOTE_PATH
# e.g. make_relative_remote "/home/user/website" "/var/www/html" should return "/var/www/html/website"
# 1st argument: SRC_PATH, 2nd argument: REMOTE_PATH, 3rd argument: EXPECTED_REMOTE_PATH
test_make_relative_remote() {
  setup
  REMOTE_PATH=$1
  SRC_PATH=$2
  EXPECTED_REMOTE_PATH=$3

  echo -e "${GREEN}REMOTE_PATH='$REMOTE_PATH' SRC_PATH='$SRC_PATH' EXPECTED_REMOTE_PATH='$EXPECTED_REMOTE_PATH'" 
  # Should I cd into the test_dir?
  make_relative_remote

  if [[ "$REMOTE_PATH" != "$EXPECTED_REMOTE_PATH" ]]; then
      echo -e "${RED}Test failed for SRC_PATH='$SRC_PATH' and REMOTE_PATH='$REMOTE_PATH': expected '$EXPECTED_REMOTE_PATH', got '$REMOTE_PATH'.${NC}"
      return
  fi
}

setup() {
  mkdir -p "test_dir/wp-content"
  mkdir -p "test_dir/local/wp-content/uploads"
  mkdir -p "test_dir/local/wp-content/plugins/mu-plugins"
  mkdir -p "test_dir/local/wp-content/themes"

  mkdir -p "test_dir/remote/"

  echo "Sample upload file" > "test_dir/local/wp-content/uploads/sample_upload.txt"
  echo "Sample plugin file" > "test_dir/local/wp-content/plugins/sample_plugin.txt"
  touch "test_dir/local/wp-content/plugins/mu-plugins/.gitkeep"
  echo "Sample theme file" > "test_dir/local/wp-content/themes/sample_theme.txt"

  echo "Created test_dir with wp-content structure and sample files."
}

cleanup() {
  rm -rf ./test_dir
}

# Test cases, make remote directory relative to to the tests directory
test_make_relative_remote "" "." ""
test_make_relative_remote "./wp-content" "./wp-content" "./wp-content"
# Ok, I think I am still not understanding how to use make relative remote. I need to test the following scenarios:
# Need to walk through the actual scenerio seen, with the source being .
# REMOTE_PATH=/wp-content
#SRC_PATH=.
#remote = ./wp-content
#source (where I am at locally)= . (current folder), and aim is to make sure excludes goes from the base wp-content/uploads/
# but can't test this... because it will start with top-level folder
test_make_relative_remote "/wp-content" "." "/wp-content"
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