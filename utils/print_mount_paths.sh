#!/bin/bash

set -e

print_mount_paths() {
  local mount_path=$1
  # Print the mounted source path and base mount path, listed in positions 4 and 5 of the resulting string
  grep "$mount_path" /proc/self/mountinfo | awk '{print $4, $5}'
}
