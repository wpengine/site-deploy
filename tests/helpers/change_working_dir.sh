#!/bin/bash

set -e

# Change the working directory to the target directory and run the given command
change_working_dir() {
  local target_dir=$1
  local orig_dir; orig_dir=$(pwd)
  shift

  (
    cd "$target_dir" || exit 1
    # Restore to the original directory after the command is run
    trap 'cd "$orig_dir"' EXIT
    "$@"
  )
}
