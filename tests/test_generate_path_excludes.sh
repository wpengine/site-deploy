#!/bin/bash

set -e

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/helpers/common.sh"
source "${SCRIPT_DIR}/helpers/change_working_dir.sh"
source "${SCRIPT_DIR}/../utils/generate_path_excludes.sh"

test_determine_source_exclude_paths() {
  run_test_determine_source_exclude_paths() {
    export SRC_PATH=$1
    local expected_base_path=$2
    local expected_mu_dir_path=$3

    {
      IFS= read -r base_path || base_path=""
      IFS= read -r mu_dir_path || mu_dir_path=""
    } <<< "$(determine_source_exclude_paths)"

    if [[ "${base_path}" != "${expected_base_path}" || "${mu_dir_path}" != "${expected_mu_dir_path}" ]]; then
      read -r mounted_source_path _ <<< "$(print_mount_paths "tests/fixtures/src")"
      echo -e "${RED}Test failed for SRC_PATH='${SRC_PATH}': expected '$expected_base_path, $expected_mu_dir_path', got '$base_path, $mu_dir_path'.${NC}"
      echo -e "${BLUE}INFO: mounted_source_path='${mounted_source_path}, pwd=$(pwd)'${NC}"
      exit 1
    fi
  }

  mount_from_root() {
    echo -e "${BLUE}INFO: mounting from /site...${NC}"

    # Mock the print_mount_paths function
    print_mount_paths() {
      # shellcheck disable=SC2317
      printf "/path/to/site /site"
    }

    # Workdir -> src directory
    change_working_dir "tests/fixtures/src" run_test_determine_source_exclude_paths "wp-content"             "/wp-content/" "/wp-content/mu-plugins/"
    change_working_dir "tests/fixtures/src" run_test_determine_source_exclude_paths "wp-content/"            "/"            "/mu-plugins/"
    change_working_dir "tests/fixtures/src" run_test_determine_source_exclude_paths "wp-content/mu-plugins"  "/"            "/mu-plugins/"
    change_working_dir "tests/fixtures/src" run_test_determine_source_exclude_paths "wp-content/mu-plugins/" ""             "/"
    change_working_dir "tests/fixtures/src" run_test_determine_source_exclude_paths "wp-content/plugins"     ""             ""
    change_working_dir "tests/fixtures/src" run_test_determine_source_exclude_paths "wp-content/plugins/"    ""             ""
    change_working_dir "tests/fixtures/src" run_test_determine_source_exclude_paths "."                      "/wp-content/" "/wp-content/mu-plugins/"

    # Workdir -> wp-content directory
    change_working_dir "tests/fixtures/src/wp-content" run_test_determine_source_exclude_paths "mu-plugins"  "/" "/mu-plugins/"
    change_working_dir "tests/fixtures/src/wp-content" run_test_determine_source_exclude_paths "mu-plugins/" ""  "/"
    change_working_dir "tests/fixtures/src/wp-content" run_test_determine_source_exclude_paths "plugins"     ""  ""
    change_working_dir "tests/fixtures/src/wp-content" run_test_determine_source_exclude_paths "plugins/"    ""  ""
    change_working_dir "tests/fixtures/src/wp-content" run_test_determine_source_exclude_paths "."           "/" "/mu-plugins/"
  }

  mount_from_wp_content() {
    echo -e "${BLUE}INFO: mounting from /site/wp-content...${NC}"

    # Mock the print_mount_paths function
    print_mount_paths() {
      # shellcheck disable=SC2317
      printf "/path/to/site/wp-content /site"
    }

    # Workdir -> src directory
    change_working_dir "tests/fixtures/src"            run_test_determine_source_exclude_paths "." "/" "/mu-plugins/"

    # Workdir -> wp-content directory
    change_working_dir "tests/fixtures/src/wp-content" run_test_determine_source_exclude_paths "." "/" "/mu-plugins/"
  }

  mount_from_mu_plugins() {
    echo -e "${BLUE}INFO: mounting from /site/mu-plugins...${NC}"

    # Mock the print_mount_paths function
    print_mount_paths() {
      # shellcheck disable=SC2317
      printf "/path/to/site/wp-content/mu-plugins /site"
    }

    # Workdir -> src directory
    change_working_dir "tests/fixtures/src"                       run_test_determine_source_exclude_paths "." "" "/"

    # Workdir -> mu-plugins directory
    change_working_dir "tests/fixtures/src/wp-content/mu-plugins" run_test_determine_source_exclude_paths "." "" "/"
  }

  mount_from_plugins() {
    echo -e "${BLUE}INFO: mounting from /site/plugins...${NC}"

    # Mock the print_mount_paths function
    print_mount_paths() {
      # shellcheck disable=SC2317
      printf "/path/to/site/wp-content/plugins /site"
    }

    # Workdir -> src directory
    change_working_dir "tests/fixtures/src"                    run_test_determine_source_exclude_paths "." "" ""

    # Workdir -> plugins directory
    change_working_dir "tests/fixtures/src/wp-content/plugins" run_test_determine_source_exclude_paths "." "" ""
  }

  mount_from_root
  mount_from_wp_content
  mount_from_mu_plugins
  mount_from_plugins

  echo -e "${GREEN}All tests passed for determining the source excludes path.${NC}"
}

test_determine_remote_exclude_paths() {
  run_test_determine_remote_exclude_paths() {
    export REMOTE_PATH=$1
    local expected_base_path=$2
    local expected_mu_dir_path=$3

    {
      IFS= read -r base_path || base_path=""
      IFS= read -r mu_dir_path || mu_dir_path=""
    } <<< "$(determine_remote_exclude_paths)"

    if [[ "${base_path}" != "${expected_base_path}" || "${mu_dir_path}" != "${expected_mu_dir_path}" ]]; then
      echo -e "${RED}Test failed for REMOTE_PATH='${SRC_PATH}': expected '$expected_base_path, $expected_mu_dir_path', got '$base_path, $mu_dir_path'.${NC}"
      exit 1
    fi
  }

  run_test_determine_remote_exclude_paths ""                       "/wp-content/" "/wp-content/mu-plugins/"
  run_test_determine_remote_exclude_paths "wp-content"             "/"            "/mu-plugins/"
  run_test_determine_remote_exclude_paths "wp-content/"            "/"            "/mu-plugins/"
  run_test_determine_remote_exclude_paths "wp-content/mu-plugins"  ""             "/"
  run_test_determine_remote_exclude_paths "wp-content/mu-plugins/" ""             "/"
  run_test_determine_remote_exclude_paths "wp-content/plugins/"    ""             ""

  echo -e "${GREEN}All tests passed for determining the remote excludes path.${NC}"
}

test_generate_source_exclude_from() {
  export SRC_PATH="."
  local output
  local expected_output

  # Mock the print_mount_paths function
  print_mount_paths() {
    # shellcheck disable=SC2317
    printf "/path/to/site /site"
  }

  output=$(generate_source_exclude_from)
  expected_output=$(cat "tests/fixtures/excludes/source_exclude_from.txt")

  if [[ "$output" != "$expected_output" ]]; then
    echo -e "${RED}Test failed: generated output does not match expected output.${NC}"
    echo -e "${BLUE}Generated output:${NC}"
    echo "$output"
    echo -e "${BLUE}Expected output:${NC}"
    echo "$expected_output"
    exit 1
  fi

  echo -e "${GREEN}Test passed for source exclude from: generated output matches expected output.${NC}"
}

test_generate_remote_excludes() {
  export REMOTE_PATH=""
  local output
  local expected_output

  output=$(generate_remote_excludes)
  expected_output=$(cat "tests/fixtures/excludes/remote_excludes.txt")

  if [[ "$output" != "$expected_output" ]]; then
    echo -e "${RED}Test failed: generated output does not match expected output.${NC}"
    echo -e "${BLUE}Generated output:${NC}"
    echo "$output"
    echo -e "${BLUE}Expected output:${NC}"
    echo "$expected_output"
    exit 1
  fi

  echo -e "${GREEN}Test passed for source exclude from: generated output matches expected output.${NC}"
}

main() {
  test_determine_source_exclude_paths
  test_determine_remote_exclude_paths
  test_generate_source_exclude_from
  test_generate_remote_excludes
}

main
