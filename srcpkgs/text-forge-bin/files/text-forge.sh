#!/bin/sh
printf '\033c\033]0;%s\a' Text Forge
/etc/text-forge/TextForge.x86_64 "$@"
