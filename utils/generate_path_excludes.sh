#!/bin/bash

set -e
shopt -s extglob

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the print_mount_paths.sh file relative to the current script's location
source "${SCRIPT_DIR}/print_mount_paths.sh"

# Determine the source paths to exclude from the deployment
#
# The function returns three values: the absolute base path for prefixing excluded files,
# the absolute mu-plugins path, and a debug string indicating which switch case was matched.
determine_source_exclude_paths() {
  local base_path
  local mu_dir_path
  local debug

  read -r mounted_source_path base_mount_path <<< "$(print_mount_paths "/wp-content")"

  if [[ -n "${SRC_PATH}" && "${SRC_PATH}" != '.' ]] ||
  [[ "$(pwd)" == @(*wp-content|*mu-plugins) ]] ||
  [[ "$(pwd)" == "$base_mount_path" && -n "${mounted_source_path}" ]]; then
    if [[ -n "${SRC_PATH}" && "${SRC_PATH}" != '.' ]]; then
      case "${SRC_PATH}" in
        wp-content )
          base_path="/wp-content/"
          mu_dir_path="/wp-content/mu-plugins/"
          debug="SRC_PATH switch: matched 'wp-content'"
          ;;
        wp-content/ | *mu-plugins )
          base_path="/"
          mu_dir_path="/mu-plugins/"
          debug="SRC_PATH switch: 'wp-content/ | *mu-plugins'"
          ;;
        *mu-plugins/ )
          mu_dir_path="/"
          debug="SRC_PATH switch: '*mu-plugins/'"
          ;;
      esac
    else
      # Iterate over the possible paths and break when a match is found
      # !!! Ordering is important for the switch cases !!!
      for value in "$(pwd)" "$mounted_source_path"; do
        case "$value" in
          *wp-content )
            base_path="/"
            mu_dir_path="/mu-plugins/"
            debug="Matched: *wp-content"
            break
            ;;
          *mu-plugins )
            mu_dir_path="/"
            debug="Matched: *wp-content/mu-plugins"
            break
            ;;
        esac
      done
    fi
  fi

  printf "%s\n%s\n%s\n" "$base_path" "$mu_dir_path" "$debug"
}

determine_remote_exclude_paths() {
  local base_path
  local mu_dir_path
  local debug="default"

  if [[ -n "${REMOTE_PATH}" ]]; then
    case "$REMOTE_PATH" in
      wp-content?(/) )
        base_path=""
        mu_dir_path="mu-plugins/"
        debug="REMOTE_PATH switch: 'wp-content?(/)'"
        ;;
      wp-content/mu-plugins?(/) )
        mu_dir_path=""
        debug="REMOTE_PATH switch: 'wp-content/mu-plugins'"
        ;;
    esac
  fi

  printf "%s\n%s\n%s\n" "$base_path" "$mu_dir_path" "$debug"
}

# Generate a list of files to exclude from the deployment
#
# The list is output to stdout, which can be used as an argument to --exclude-from.
print_dynamic_excludes() {
  local func=$1
  {
    IFS= read -r base_path
    IFS= read -r mu_dir_path
    IFS= read -r debug
  } <<< "$($func)"

  if [[ -n "$base_path" && -n "$mu_dir_path" ]]; then
    cat << EOF
# WordPress specific files (dynamic paths)
${base_path}uploads/
${base_path}blogs.dir/
${base_path}upgrade/*
${base_path}backup-db/*
${base_path}advanced-cache.php
${base_path}wp-cache-config.php
${base_path}cache/*
${base_path}cache/supercache/*

# WP Engine specific files (dynamic paths)
${base_path}object-cache.php
${base_path}drop-ins/
${base_path}drop-ins/wp-cache-memcached*
${base_path}mysql.sql
${mu_dir_path}mu-plugin.php
${mu_dir_path}slt-force-strong-passwords.php
${mu_dir_path}wpengine-security-auditor.php
${mu_dir_path}stop-long-comments.php
${mu_dir_path}force-strong-passwords*
${mu_dir_path}wpengine-common*
${mu_dir_path}wpe-wp-sign-on-plugin*
${mu_dir_path}wpe-elasticpress-autosuggest-logger*
${mu_dir_path}wpe-cache-plugin*
${mu_dir_path}wp-cache-memcached*

# Local specific (dynamic paths)
${mu_dir_path}local-by-flywheel-live-link-helper.php

#################### Debug: ${debug}
EOF
  elif [[ -n "$mu_dir_path" ]]; then
    cat << EOF
# WP Engine specific files (dynamic paths)
${mu_dir_path}mu-plugin.php
${mu_dir_path}slt-force-strong-passwords.php
${mu_dir_path}wpengine-security-auditor.php
${mu_dir_path}stop-long-comments.php
${mu_dir_path}force-strong-passwords*
${mu_dir_path}wpengine-common*
${mu_dir_path}wpe-wp-sign-on-plugin*
${mu_dir_path}wpe-elasticpress-autosuggest-logger*
${mu_dir_path}wpe-cache-plugin*
${mu_dir_path}wp-cache-memcached*

# Local specific (dynamic paths)
${mu_dir_path}local-by-flywheel-live-link-helper.php

#################### Debug: ${debug}
EOF
  else
    cat << EOF
# Version Control
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
wp-content/drop-ins/
wp-content/drop-ins/wp-cache-memcached*
wp-content/mysql.sql
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

# Local specific
wp-content/local-by-flywheel-live-link-helper.php
EOF
  fi
}

generate_source_exclude_from() {
  print_dynamic_excludes determine_source_exclude_paths
}

generate_remote_excludes() {
  print_dynamic_excludes determine_remote_exclude_paths | grep -Ev '^\s*(#|$)' | awk '{printf "--exclude='\''%s'\'' ", $0}' | sed 's/[[:space:]]*$//'
}
