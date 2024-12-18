#!/bin/bash

set -e
shopt -s extglob

# Dynamic Excludes
#
# This script generates two lists of files to exclude; one for the source, and one for the remote.
#
# Notes about excluded files:
#
#   Version Control
#   NOTE:
#     WP Engine does not support server side versioning so hosting any version control
#     on the server would not be advantageous.
#
#   WordPress specific files
#   NOTE:
#     These files are excluded from the deploy so as to prevent unwanted errors from occurring,
#     such as accidentally deploying a local version of wp-config.php or accidentally deleting
#     wp-content/uploads/ if a --delete flag is passed while deploying root. Most paths here
#     are ignored in the WPE sample .gitignore per best practice.
#
#   WP Engine specific files
#   NOTE:
#     These files are specific to running a WordPress site at WP Engine and would
#     likely result in a broken production site if modified in production (in
#     fact, permissions would prevent modification for many of these files). While
#     some of these files (such as those in /_wpeprivate) would be extremely large
#     and completely useless in the context of local WordPress development, others
#     (such as some of the WP Engine managed plugins) might be useful in rare
#     circumstances to have as a reference for debugging purposes.

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the print_mount_paths.sh file relative to the current script's location
source "${SCRIPT_DIR}/print_mount_paths.sh"

# Determine the source paths to exclude from the deployment
determine_source_exclude_paths() {
  local base_path
  local mu_dir_path

  read -r mounted_source_path _ <<< "$(print_mount_paths "wp-content")"

  # elif [[ "$(pwd)" == @(*wp-content|*mu-plugins) ]] || [[ "$(pwd)" == "$base_mount_path" && -n "${mounted_source_path}" ]]; then

  if [[ -n "${SRC_PATH}" && "${SRC_PATH}" != '.' ]]; then
    case "${SRC_PATH}" in
      wp-content )
        base_path="/wp-content/"
        mu_dir_path="/wp-content/mu-plugins/"
        ;;
      wp-content/ | *mu-plugins )
        base_path="/"
        mu_dir_path="/mu-plugins/"
        ;;
      *mu-plugins/ )
        mu_dir_path="/"
        ;;
    esac
  elif [[ "$(pwd)" != *wp-content* && "${mounted_source_path}" != *wp-content* ]]; then
    base_path="/wp-content/"
    mu_dir_path="/wp-content/mu-plugins/"
  else
    # Iterate over the possible paths and break when a match is found
    # !!! Ordering is important for the switch cases !!!
    for value in "$(pwd)" "$mounted_source_path"; do
      case "$value" in
        *wp-content )
          base_path="/"
          mu_dir_path="/mu-plugins/"
          break
          ;;
        *mu-plugins )
          mu_dir_path="/"
          break
          ;;
      esac
    done
  fi

  printf "%s\n%s\n" "$base_path" "$mu_dir_path"
}

determine_remote_exclude_paths() {
  local base_path
  local mu_dir_path

  if [[ -z "${REMOTE_PATH}" ]]; then
    base_path="/wp-content/"
    mu_dir_path="/wp-content/mu-plugins/"
  else
    case "$REMOTE_PATH" in
      wp-content?(/) )
        base_path="/"
        mu_dir_path="/mu-plugins/"
        ;;
      wp-content/mu-plugins?(/) )
        mu_dir_path="/"
        ;;
    esac
  fi

  printf "%s\n%s\n" "$base_path" "$mu_dir_path"
}

# Generate the dynamic list of files to exclude from the deployment
print_dynamic_excludes() {
  local func=$1
  local delimiter=$2
  local output=""

  {
    IFS= read -r base_path
    IFS= read -r mu_dir_path
  } <<< "$($func)"

  local wp_content_exclude_paths=(
    # WordPress specific files and directories
    uploads/
    blogs.dir/
    upgrade/*
    backup-db/*
    advanced-cache.php
    wp-cache-config.php
    cache/*
    cache/supercache/*
    # WP Engine specific files and directories
    object-cache.php
    drop-ins/
    drop-ins/wp-cache-memcached*
    mysql.sql
  )

  local mu_plugin_exclude_paths=(
    # WP Engine specific files and directories
    mu-plugin.php
    slt-force-strong-passwords.php
    wpengine-security-auditor.php
    stop-long-comments.php
    force-strong-passwords*
    wpengine-common*
    wpe-wp-sign-on-plugin*
    wpe-elasticpress-autosuggest-logger*
    wpe-cache-plugin*
    wp-cache-memcached*
    # Local specific files
    local-by-flywheel-live-link-helper.php
  )

  if [[ -n "$base_path" ]]; then
    output+="${delimiter}### Dynamic file and directory exclusions${delimiter}"
    for path in "${wp_content_exclude_paths[@]}"; do
      output+="${base_path}$path${delimiter}"
    done
  fi

  if [[ -n "$mu_dir_path" ]]; then
    output+="${delimiter}### Dynamic mu-plugin file and directory exclusions${delimiter}"
    for path in "${mu_plugin_exclude_paths[@]}"; do
      output+="${mu_dir_path}$path${delimiter}"
    done
  fi

  echo -e "$output"
}

generate_source_exclude_from() {
  local dynamic_excludes; dynamic_excludes=$(print_dynamic_excludes determine_source_exclude_paths "\n")

  cat << EOF
# Version Control
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
wp-config.php

# WP Engine specific files and directories
.smushit-status
.gitattributes
.wpe-devkit/
.wpengine-conf/
_wpeprivate
$(echo -e "$dynamic_excludes")
EOF
}

generate_remote_excludes() {
  local dynamic_excludes; dynamic_excludes=$(print_dynamic_excludes determine_remote_exclude_paths "\n")

  cat << EOF | grep -Ev '^\s*(#|$)|\s+#' | awk '{printf "--exclude='\''%s'\'' ", $0}' | sed 's/[[:space:]]*$//'
# WordPress specific files
wp-config.php

# WP Engine specific files and directories
.smushit-status
.gitattributes
.wpe-devkit/
.wpengine-conf/
_wpeprivate
$(echo -e "$dynamic_excludes")
EOF
}
