#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/../exclude-from.sh"

test_generate_exclude_from() {
  export REMOTE_PATH=""
  expected_output="# Version Control
# NOTE:
#    WP Engine does not support server side versioning so hosting any version control
#    on the server would not be advantageous.

*~
.git
.github
.gitignore
.DS_Store
.svn
.cvs
*.bak
*.swp
Thumbs.db

# WordPress specific files
# NOTE:
#     These files are excluded from the deploy so as to prevent unwanted errors from occurring,
#     such as accidentally deploying a local version of wp-config.php or accidentally deleting
#     wp-content/uploads/ if a --delete flag is passed while deploying root. Most paths here
#     are ignored in the WPE sample .gitignore per best practice.
wp-config.php
wp-content/uploads/
wp-content/blogs.dir/
wp-content/upgrade/*
wp-content/backup-db/*
wp-content/advanced-cache.php
wp-content/wp-cache-config.php
wp-content/cache/*
wp-content/cache/supercache/*

# WP Engine specific files
# NOTE:
#   These files are specific to running a WordPress site at WP Engine and would
#   likely result in a broken production site if modified in production (in
#   fact, permissions would prevent modification for many of these files). While
#   some of these files (such as those in /_wpeprivate) would be extremely large
#   and completely useless in the context of local WordPress development, others
#   (such as some of the WP Engine managed plugins) might be useful in rare
#   circumstances to have as a reference for debugging purposes.
.smushit-status
.gitattributes
.wpe-devkit/
.wpengine-conf/
_wpeprivate
wp-content/object-cache.php
wp-content/mu-plugins/mu-plugin.php
wp-content/mu-plugins/slt-force-strong-passwords.php
wp-content/mu-plugins/wpengine-security-auditor.php
wp-content/mu-plugins/stop-long-comments.php
wp-content/mu-plugins/force-strong-passwords*
wp-content/mu-plugins/wpengine-common*
wp-content/mu-plugins/wpe-wp-sign-on-plugin*
wp-content/mu-plugins/wpe-elasticpress-autosuggest-logger*
wp-content/mu-plugins/wpe-cache-plugin*
wp-content/mu-plugins/wp-cache-memcached*
wp-content/drop-ins/
wp-content/drop-ins/wp-cache-memcached*
wp-content/mysql.sql

# Local specific
wp-content/mu-plugins/local-by-flywheel-live-link-helper.php"

  # Show the diff between the generated list and the expected output
  if diff <(generate_exclude_from) <(echo "$expected_output"); then
    echo -e "${GREEN}Test passed for generating excludes list with REMOTE_PATH='${REMOTE_PATH}'.${NC}"
  else
    echo -e "${RED}Test failed for generating excludes list with REMOTE_PATH='${REMOTE_PATH}'.${NC}"
  fi
}

test_determine_exclude_paths() {
  export REMOTE_PATH="wp-content"
  expected_base_path=""
  expected_mu_dir_path="mu-plugins/"

  # Run the function and capture the output
  output=$(determine_exclude_paths)
  {
    IFS= read -r base_path
    IFS= read -r mu_dir_path
  } <<< "$output"

  # Check the assigned paths
  if [[ "$base_path" == "$expected_base_path" && "$mu_dir_path" == "$expected_mu_dir_path" ]]; then
    echo -e "${GREEN}Test passed for updating excludes list file paths with REMOTE_PATH='${REMOTE_PATH}'.${NC}"
  else
    echo -e "${RED}Test failed for updating excludes list file paths with REMOTE_PATH='${REMOTE_PATH}'.${NC}"
  fi
}

test_rsync_with_excludes() {
  export REMOTE_PATH=$1
  echo -e "${BLUE}--- REMOTE_PATH: '$REMOTE_PATH'${NC}"

  local exclude_from; exclude_from="$(generate_exclude_from)"
  local fixture_path="$SCRIPT_DIR/data"

  # Capture the output of the rsync command
  output=$(rsync --dry-run --verbose --recursive --exclude-from=<(echo "$exclude_from") "$fixture_path" .)

  # Check if the output contains the expected file
  if echo "$output" | grep -q "test-plugin.php"; then
    echo -e "${GREEN}Test passed for rsync syncing files: test-plugin.php included.${NC}"
  else
    echo -e "${RED}Test failed for rsync syncing files: test-plugin.php excluded.${NC}"
  fi

  # Check that the output does not contain the excluded file
  if echo "$output" | grep -q "mu-plugin.php"; then
    echo -e "${RED}Test failed for rsync parsing excludes: mu-plugin.php included.${NC}"
  else
    echo -e "${GREEN}Test passed for rsync parsing excludes: mu-plugin.php excluded.${NC}"
  fi
}

main() {
  test_generate_exclude_from
  test_determine_exclude_paths
  test_rsync_with_excludes ""
  test_rsync_with_excludes "wp-content"
  test_rsync_with_excludes "wp-content/mu-plugins"
}

main
