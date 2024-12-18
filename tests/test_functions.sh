#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/helpers/common.sh"
source "${SCRIPT_DIR}/../utils/functions.sh"

# First argument represents the value of the FLAGS variable.
# The rest of the arguments represent the expected values of the FLAGS_ARRAY.
#
# usage: test_parse_flags <FLAGS> <EXPECTED_FLAGS...>
test_parse_flags() {
  local test_case=$1
  shift
  local expected_args=("$@")

  parse_flags "$test_case"

  local actual_count="${#FLAGS_ARRAY[@]}"
  local expected_count="${#expected_args[@]}"

  if [[ "$actual_count" -ne "$expected_count" ]]; then
    echo -e "${RED}Test failed for FLAGS='$test_case': expected $expected_count arguments, got $actual_count."
    echo -e "\tActual arguments: ${FLAGS_ARRAY[*]}${NC}"
    return
  fi

  for i in "${!expected_args[@]}"; do
    if [[ "${FLAGS_ARRAY[$i]}" != "${expected_args[$i]}" ]]; then
      echo -e "${RED}Test failed for FLAGS='$test_case': expected '${expected_args[$i]}', got '${FLAGS_ARRAY[$i]}'.${NC}"
      return
    fi
  done

  echo -e "${GREEN}Test passed for FLAGS=\"$test_case\".${NC}"
}

# Test cases
test_parse_flags \
  "-azvr --inplace --exclude='.*'" \
  "-azvr" \
  "--inplace" \
  "--exclude=.*"

test_parse_flags \
  '-azvr --inplace --exclude=".*"' \
  "-azvr" \
  "--inplace" \
  "--exclude=.*"

test_parse_flags \
  "-azvr --filter=':- .gitignore' --exclude='.*'" \
  "-azvr" \
  "--filter=:- .gitignore" \
  "--exclude=.*"

test_parse_flags \
  "-avzr --delete --filter='P /wp-uploads/**'" \
  "-avzr" \
  "--delete" \
  "--filter=P /wp-uploads/**"

test_parse_flags \
  "-avzr --delete --exclude='\$dollar'" \
  "-avzr" \
  "--delete" \
  "--exclude=\$dollar"

test_parse_flags \
  "-avzr --exclude='\`back-ticks\`'" \
  "-avzr" \
  "--exclude=\`back-ticks\`"

test_parse_flags \
  "-avzr --exclude='path\\with\\backslash'" \
  "-avzr" \
  "--exclude=path\\with\\backslash"
