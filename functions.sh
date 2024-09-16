#!/bin/bash

set -e

# Function to parse FLAGS into an array
# 
# Bash doesn't respect quotes when splitting the FLAGS string on whitespace
# which can lead to incorrect splitting on arguments like --filter=':- .gitignore'.
#
# xargs does respect quotes, so we use that here to convert the string into a null-delimited
# sequence of arguments. We then read that sequence into an array by splitting on the null character.
#
# https://superuser.com/questions/1529226/get-bash-to-respect-quotes-when-word-splitting-subshell-output
parse_flags() {
  local flags="$1"
  FLAGS_ARRAY=()
  while IFS= read -r -d '' flag; do FLAGS_ARRAY+=("$flag"); done < <(echo "$flags" | xargs printf '%s\0')
}

print_deployment_info() {
  echo "Deploying your code to:"
  echo -e "\t${WPE_ENV_NAME}"
  echo -e "with the following ${#FLAGS_ARRAY[@]} rsync argument(s):"
  for flag in "${FLAGS_ARRAY[@]}"; do
    echo -e "\t$flag"
  done
}

# Function to check REMOTE_PATH and move contents of SRC_PATH
make_relative_remote() {
    if [ -z "$REMOTE_PATH" ]; then
        echo "REMOTE_PATH is not set. Exiting function."
        return
    fi

    if [ "$SRC_PATH" == "$REMOTE_PATH" ]; then
        echo "SRC_PATH and REMOTE_PATH are the same. Exiting function."
        return
    fi

    mkdir -p "$REMOTE_PATH"

    if [ "$SRC_PATH" == "." ]; then
        # Use a temporary directory to avoid moving REMOTE_PATH into itself
        TMP_DIR=$(mktemp -d)
        mv "$SRC_PATH"/* "$TMP_DIR"
        mv "$TMP_DIR"/* "$REMOTE_PATH"
        rmdir "$TMP_DIR"
    else
        mv "$SRC_PATH"/* "$REMOTE_PATH"
    fi
}



