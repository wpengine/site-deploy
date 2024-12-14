#!/bin/bash

set -e

log_debug() {
  local subject; subject="$1"
  local message; message="$2"

  cat <<EOF

####################
$subject

$message
####################

EOF
}
