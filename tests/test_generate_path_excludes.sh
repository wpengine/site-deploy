#!/bin/bash

set -e

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/helpers/common.sh"
source "${SCRIPT_DIR}/../utils/generate_path_excludes.sh"

test_determine_exclude_paths() {
  run_test_determine_exclude_paths() {
    export REMOTE_PATH=$1
    local expected_base_path=$2
    local expected_mu_dir_path=$3

    {
      IFS= read -r base_path || base_path=""
      IFS= read -r mu_dir_path || mu_dir_path=""
    } <<< "$(determine_exclude_paths)"

    if [[ "${base_path}" != "${expected_base_path}" || "${mu_dir_path}" != "${expected_mu_dir_path}" ]]; then
      echo -e "${RED}Test failed for REMOTE_PATH='${REMOTE_PATH}'': expected '$expected_base_path, $expected_mu_dir_path', got '$base_path, $mu_dir_path'.${NC}"
      exit 1
    fi
  }

  run_test_determine_exclude_paths "."                      "/wp-content/" "/wp-content/mu-plugins/"
  run_test_determine_exclude_paths ""                       "/wp-content/" "/wp-content/mu-plugins/"
  run_test_determine_exclude_paths "wp-content"             "/"            "/mu-plugins/"
  run_test_determine_exclude_paths "wp-content/"            "/"            "/mu-plugins/"
  run_test_determine_exclude_paths "wp-content/mu-plugins"  ""             "/"
  run_test_determine_exclude_paths "wp-content/mu-plugins/" ""             "/"
  run_test_determine_exclude_paths "wp-content/plugins"     ""             ""
  run_test_determine_exclude_paths "wp-content/plugins/"    ""             ""

  echo -e "${GREEN}All tests passed for determining the excludes path.${NC}"
}

test_generate_exclude_from() {
  run_test_generate_exclude_from() {
    export REMOTE_PATH=$1
    local output
    local expected_output_file=$2
    local expected_output

    output=$(generate_exclude_from)
    expected_output=$(cat "${expected_output_file}")

    if [[ "$output" != "$expected_output" ]]; then
      echo -e "${RED}Test failed for REMOTE_PATH='${REMOTE_PATH}'': generated output does not match expected output.${NC}"
      echo -e "${BLUE}Generated output:${NC}"
      echo "$output"
      echo -e "${BLUE}Expected output from ${expected_output_file}:${NC}"
      echo "$expected_output"
      exit 1
    fi
  }
  
  run_test_generate_exclude_from "."                      "tests/fixtures/excludes/exclude_from_root.txt"
  run_test_generate_exclude_from ""                       "tests/fixtures/excludes/exclude_from_root.txt"
  run_test_generate_exclude_from "wp-content"             "tests/fixtures/excludes/exclude_from_wp_content.txt"
  run_test_generate_exclude_from "wp-content/"            "tests/fixtures/excludes/exclude_from_wp_content.txt"
  run_test_generate_exclude_from "wp-content/mu-plugins"  "tests/fixtures/excludes/exclude_from_mu_plugins.txt"
  run_test_generate_exclude_from "wp-content/mu-plugins/" "tests/fixtures/excludes/exclude_from_mu_plugins.txt"
  run_test_generate_exclude_from "wp-content/plugins"     "tests/fixtures/excludes/exclude_from_safe_directories.txt"
  run_test_generate_exclude_from "wp-content/plugins/"    "tests/fixtures/excludes/exclude_from_safe_directories.txt"

  echo -e "${GREEN}All tests passed for generating exclude-from rules.${NC}"
}

main() {
  test_determine_exclude_paths
  test_generate_exclude_from
}

main
