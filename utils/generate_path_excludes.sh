#!/bin/bash

set -e
shopt -s extglob

# Dynamic Excludes
#
# This script generates a list of files to exclude from the rsync deployment.
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

determine_exclude_paths() {
  local base_path; base_path="/wp-content/"
  local mu_dir_path; mu_dir_path="/wp-content/mu-plugins/"

  remote_path_is_set() {
    [[ -n "${REMOTE_PATH}" && "${REMOTE_PATH}" != '.' ]]
  }

  make_exclude_paths_relative_to_remote() {
    case "${REMOTE_PATH}" in
      wp-content?(/) )
        # REMOTE_PATH is the wp-content directory
        base_path="/"
        mu_dir_path="/mu-plugins/"
        ;;
      wp-content/mu-plugins?(/) )
        # REMOTE_PATH is the mu-plugins directory
        base_path=""
        mu_dir_path="/"
        ;;
      * )
        # REMOTE_PATH is set, but it's not the site root, wp-content, or mu-plugins.
        # No dynamic excludes needed.
        base_path=""
        mu_dir_path=""
        ;;
    esac
  }

  if remote_path_is_set; then
    make_exclude_paths_relative_to_remote
  fi

  printf "%s\n%s\n" "$base_path" "$mu_dir_path"
}

# Generate the dynamic list of paths to exclude from the deployment
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

generate_exclude_from() {
  local dynamic_excludes; dynamic_excludes=$(print_dynamic_excludes determine_exclude_paths "\n")

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
