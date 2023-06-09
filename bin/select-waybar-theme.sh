#!/usr/bin/env bash

THEME=$1

if [ -z ${THEME+x} ]; then
  echo "Usage: link-waybar-theme.sh THEME_NAME"
else
  ln -sf ~/.config/waybar/$THEME.jsonc ~/.config/waybar/config.jsonc
  ln -sf ~/.config/waybar/$THEME.css ~/.config/waybar/style.css
fi
