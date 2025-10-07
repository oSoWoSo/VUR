#!/bin/bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Allow users to override command-line options
if [[ -f "$XDG_CONFIG_HOME/harmonymusic-flags.conf" ]]; then
   HARMONYMUSIC_USER_FLAGS="$(grep -v '^#' "$XDG_CONFIG_HOME/harmonymusic-flags.conf")"
fi

# Launch
exec /opt/harmonymusic/harmonymusic $HARMONYMUSIC_USER_FLAGS "$@"
