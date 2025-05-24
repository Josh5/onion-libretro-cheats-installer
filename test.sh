#!/usr/bin/env bash
###
# File: test.sh
# Project: onion-libretro-cheats-installer
# File Created: Saturday, 24th May 2025 1:28:44 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Saturday, 24th May 2025 2:23:29 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd -P)"
SCRIPT_PATH="${PROJECT_ROOT:?}/src/scripts/install-cheats.sh"

# Export required variables
export appdir="${PROJECT_ROOT:?}/src"
export sdcard="${PROJECT_ROOT:?}/temp/SDCARD"

# Create required test directories
mkdir -p "${sdcard:?}"

# Terminal dimensions (characters, not pixels)
COLS=53
ROWS=29

# Terminal title
TITLE="Miyoo Sized Terminal"

# Check if st is available
if command -v st >/dev/null 2>&1; then
    st -t "$TITLE" -g ${COLS}x${ROWS} -e "$SCRIPT_PATH"
elif command -v xterm >/dev/null 2>&1; then
    xterm -T "$TITLE" -geometry ${COLS}x${ROWS} -e "$SCRIPT_PATH"
else
    echo "Error: Neither 'st' nor 'xterm' is installed. Please install one to run the menu."
    exit 1
fi

echo "Terminal exited"
