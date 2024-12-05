#!/bin/bash

set -e

# Determine the paths to exclude from the deployment
#
# Paths are inferred from the REMOTE_PATH environment variable.
#
# The function returns two paths: the relative base path for prefixing excluded files,
# and the relative mu-plugins path.
determine_exclude_paths() {
  local base_path="wp-content/"
  local mu_dir_path="wp-content/mu-plugins/"

  case "$REMOTE_PATH" in
    "wp-content")
      base_path=""
      mu_dir_path="mu-plugins/"
      ;;
    "wp-content/mu-plugins")
      base_path=""
      mu_dir_path=""
      ;;
  esac

  printf "%s\n%s\n" "$base_path" "$mu_dir_path"
}

# Generate a list of files to exclude from the deployment
#
# The list is output to stdout, which can be used as an argument to --exclude-from.
generate_exclude_from() {
  {
    IFS= read -r base_path
    IFS= read -r mu_dir_path
  } <<< "$(determine_exclude_paths)"

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
${base_path}uploads/
${base_path}blogs.dir/
${base_path}upgrade/*
${base_path}backup-db/*
${base_path}advanced-cache.php
${base_path}wp-cache-config.php
${base_path}cache/*
${base_path}cache/supercache/*

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
${base_path}object-cache.php
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
${base_path}drop-ins/
${base_path}drop-ins/wp-cache-memcached*
${base_path}mysql.sql

# Local specific
${mu_dir_path}local-by-flywheel-live-link-helper.php
EOF
}
