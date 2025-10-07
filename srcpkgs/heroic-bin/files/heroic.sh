#!/bin/bash
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Allow users to override command-line options
if [[ -f "$XDG_CONFIG_HOME/heroic-flags.conf" ]]; then
   HEROIC_USER_FLAGS="$(grep -v '^#' "$XDG_CONFIG_HOME/heroic-flags.conf")"
fi

# Launch
export ELECTRON_IS_DEV=0
exec /opt/Heroic/heroic $HEROIC_USER_FLAGS "$@"
