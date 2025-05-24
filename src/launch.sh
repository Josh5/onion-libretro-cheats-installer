#!/bin/sh
###
# File: launch.sh
# File Created: Saturday, 24th May 2025 12:06:49 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Saturday, 24th May 2025 4:57:53 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

export appdir=$(
    cd -- "$(dirname "$0")" >/dev/null 2>&1
    pwd -P
)
export sdcard="/mnt/SDCARD"
export sysdir="${sdcard:?}/.tmp_update"
export miyoodir="${sdcard:?}/miyoo"
export LD_LIBRARY_PATH="${appdir:?}/lib:/lib:/config/lib:${miyoodir:?}/lib:${sysdir:?}/lib:${sysdir:?}/lib/parasyte"
export PATH="${appdir:?}/bin:${sysdir:?}/bin:${PATH:-}"

# exec "${appdir:?}/scripts/install-cheats.sh"
exec "${sysdir:?}/bin/st" -q -e "${appdir:?}/scripts/install-cheats.sh"
