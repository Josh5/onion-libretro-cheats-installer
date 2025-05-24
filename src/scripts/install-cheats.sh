#!/bin/sh
###
# File: install-cheats.sh
# File Created: Saturday, 24th May 2025 1:33:36 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Saturday, 24th May 2025 9:11:10 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

export cheat_dir="${sdcard:?}/RetroArch/.retroarch/cheats"
export cfg_path="${sdcard:?}/RetroArch/.retroarch/retroarch.cfg"
export roms_dir="${sdcard:?}/Roms"
export config_file="${appdir:?}/config/installed-systems.ini"

mkdir -p \
    "${cheat_dir:?}" \
    "$(dirname "${config_file:?}")"

print_title() {
    printf "**** %s ****\n\n" "${*}"
}

print_step_header() {
    printf " - %s\n" "${*}"
}

print_step_point() {
    printf "   -> %s\n" "${*}"
}

print_step_error() {
    printf "   \033[31mERROR: \033[33m%s\033[0m\n" "${*}"
}

print_step_ok() {
    printf "   \033[32m[OK]\033[0m %s\n" "${*}"
}

print_step_fail() {
    printf "   \033[31m[FAIL]\033[0m %s\n" "${*}"
}

press_any_key_to_exit() {
    local exit_code=${1:-0}
    printf "\nPress any key to return [%s]..." "$exit_code"
    IFS= read -rsn1 _
    exit "$exit_code"
}

enable_cheats_cfg() {
    print_step_header "Enabling cheats in Retroarch Quick menu"
    if grep -q "^quick_menu_show_cheats" "${cfg_path:?}"; then
        sed -i 's/^quick_menu_show_cheats.*/quick_menu_show_cheats = "true"/' "${cfg_path:?}" &&
            print_step_ok "Updated existing config entry"
    else
        echo 'quick_menu_show_cheats = "true"' >>"${cfg_path:?}" &&
            print_step_ok "Added new config entry"
    fi
}

urlencode() {
    local s="$1"
    local o=""
    local c
    while [ -n "$s" ]; do
        c="${s%"${s#?}"}"
        case "$c" in
        [a-zA-Z0-9.~_-]) o="${o}${c}" ;;
        ' ') o="${o}%20" ;;
        *) o="${o}$(printf '%%%02X' "'$c")" ;;
        esac
        s="${s#?}"
    done
    printf "%s\n" "$o"
}

download_cheats_for_system() {
    local system="$1"
    local encoded_system
    encoded_system=$(urlencode "$system")
    local base_api="https://api.github.com/repos/libretro/libretro-database/contents/cht/$encoded_system"

    local cheats_json
    cheats_json=$(curl -sk "$base_api")

    if [ -z "$cheats_json" ] || ! echo "$cheats_json" | jq -e '.[] | select(.name | endswith(".cht"))' >/dev/null 2>&1; then
        print_step_fail "No cheat files found for $system"
        return
    fi

    local cheat_dir_dest="${cheat_dir:?}/${system:?}"
    mkdir -p "$cheat_dir_dest"

    local total
    total=$(echo "$cheats_json" | jq '[.[] | select(.name | endswith(".cht"))] | length')

    local completed=0
    local max_jobs=6
    local job_count=0

    print_progress() {
        local percent=$((completed * 100 / total))
        printf "   -> [%3d%%] %s\r" "$percent" "$system"
    }

    download_file() {
        local url="$1"
        local dest="$2"
        local filename="$3"
        mkdir -p "$dest"
        curl -sk -z "$dest/$filename" "$url" -o "$dest/$filename"
    }

    print_progress

    printf "%s\n" "$cheats_json" |
        jq -r '.[] | select(.name | endswith(".cht")) | @base64' |
        while IFS= read -r entry_b64; do
            _jq() {
                printf "%s" "$entry_b64" | base64 -d | jq -r "$1"
            }

            local filename url
            filename=$(_jq '.name')
            url=$(_jq '.download_url')

            download_file "$url" "$cheat_dir_dest" "$filename" &
            job_count=$((job_count + 1))

            if [ "$job_count" -ge "$max_jobs" ]; then
                wait
                completed=$((completed + job_count))
                print_progress
                job_count=0
            fi
        done

    wait
    completed=$((completed + job_count))
    print_progress
    printf "   -> \033[36m[DONE]\033[0m %s\n" "$system"
}

detect_installed_systems() {
    local ini_file="${appdir:?}/systems-matrix.ini"
    local section_found=0
    local rom_dir system_name libretro_name

    >"${config_file:?}"

    for rom_dir in "${roms_dir:?}"/*; do
        system_name=$(basename "$rom_dir")

        # Reset for each lookup
        section_found=0
        libretro_name=""

        while IFS= read -r line || [ -n "$line" ]; do
            case "$line" in
            "[systems]")
                section_found=1
                continue
                ;;
            \[*)
                section_found=0
                continue
                ;;
            esac

            if [ "$section_found" -eq 1 ]; then
                key=${line%%=*}
                value=${line#*=}
                [ "$key" = "$system_name" ] && libretro_name="$value" && break
            fi
        done <"$ini_file"

        [ -n "$libretro_name" ] && printf "%s\n" "$libretro_name" >>"${config_file:?}"
    done
}

# Main
print_title "LibRetro Cheats Installer"

enable_cheats_cfg

print_step_header "Detecting installed systems"
detect_installed_systems

if [ ! -s "${config_file:?}" ]; then
    print_step_fail "No supported systems found in Roms folder"
else
    print_step_header "Downloading cheat files"
    while IFS= read -r sys; do
        download_cheats_for_system "$sys"
    done <"${config_file:?}"
    print_step_ok "Cheat files downloaded for enabled systems"
fi

press_any_key_to_exit
