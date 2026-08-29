#!/bin/sh
printf '\033c\033]0;%s\a' TRUST
base_path="$(dirname "$(realpath "$0")")"
"$base_path/TRUST.x86_64" "$@"
