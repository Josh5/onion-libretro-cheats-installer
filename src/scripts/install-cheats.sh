#!/bin/sh
###
# File: install-cheats.sh
# File Created: Saturday, 24th May 2025 1:33:36 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 26th May 2025 11:31:55 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###

export cheat_dir="${sdcard:?}/RetroArch/.retroarch/cheats/libretro-database"
export cfg_path="${sdcard:?}/RetroArch/.retroarch/retroarch.cfg"
export roms_dir="${sdcard:?}/Roms"
export config_file="${appdir:?}/config/installed-systems.ini"

mkdir -p "$(dirname "${config_file:?}")"

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
    printf "\nPress any key to exit [%s]..." "$exit_code"
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
    local safe_system=$(printf "%s" "$system" | tr -cs 'a-zA-Z0-9' '_')
    local encoded_system=$(urlencode "$system")
    local base_api="https://api.github.com/repos/libretro/libretro-database/contents/cht/$encoded_system"
    local cheat_dir_dest="${cheat_dir:?}/${system:?}"
    local temp_ini=$(mktemp)
    local temp_script=$(mktemp)
    local progress_file=$(mktemp)

    mkdir -p "$cheat_dir_dest"
    rm -f "$temp_ini" "$temp_script" "$progress_file"

    # Fetch a list of cheat files
    local cheats_json=$(curl -sk "$base_api")
    if [ -z "$cheats_json" ] || ! echo "$cheats_json" | jq -e '.[] | select(.name | endswith(".cht"))' >/dev/null 2>&1; then
        print_step_fail "No cheat files found for $system"
        return
    fi

    # Write .ini file with itemN.filename and itemN.url
    echo "$cheats_json" | jq -r \
        '.[] | select(.name | endswith(".cht")) | [.name, .download_url] | @tsv' |
        awk -F'\t' '{
            printf("item%d.filename=%s\nitem%d.url=%s\n", ++i, $1, i, $2);
        }' >"$temp_ini"

    # Ensure we have some downloads
    local total=$(grep -c '^item[0-9]\+\.filename=' "$temp_ini")
    [ "$total" -eq 0 ] && print_step_fail "No valid entries found for $system" && rm -f "$temp_ini" && return

    # Init percent progress
    echo 0 >"$progress_file"

    # Generate and launch download worker script (max DL concurrency 5)
    cat <<EOF >"$temp_script"
#!/bin/sh
count=0
job_count=0
total=$total
while [ \$count -lt \$total ]; do
    i=\$((count + 1))
    filename=\$(grep "^item\${i}\\.filename=" "$temp_ini" | cut -d= -f2-)
    url=\$(grep "^item\${i}\\.url=" "$temp_ini" | cut -d= -f2-)
    if [ -n "\$filename" ]; then
        (
            curl -sk -z "$cheat_dir_dest/\$filename" "\$url" -o "$cheat_dir_dest/\$filename" >/dev/null 2>&1
            echo \$(((i) * 100 / total)) > "$progress_file"
        ) &
        job_count=\$((job_count + 1))
    fi

    if [ "\$job_count" -ge 5 ]; then
        wait
        job_count=0
    fi

    count=\$((count + 1))
done

wait
EOF

    chmod +x "$temp_script"
    "$temp_script" &

    # Poll progress file for updates
    local last_shown=-1
    while :; do
        [ -f "$progress_file" ] || break
        percent=$(cat "$progress_file")
        [ "$percent" = "$last_shown" ] || {
            printf "   -> [%3d%%] %s\r" "$percent" "$system"
            last_shown=$percent
        }
        [ "$percent" -ge 100 ] && break
        sleep 0.2
    done

    # Clean up temp files
    rm -f "$temp_ini" "$temp_script" "$progress_file"

    # Print final message
    printf "   -> \033[36m[DONE]\033[0m %s\n" "$system"
}

detect_installed_systems() {
    local ini_file="${appdir:?}/systems-matrix.ini"
    local section_found=0
    local rom_dir system_name libretro_name

    >"${config_file:?}"

    for rom_dir in "${roms_dir:?}"/*; do
        [ -d "$rom_dir" ] || continue # Skip files

        system_name=$(basename "$rom_dir" | tr '[:lower:]' '[:upper:]')

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

        if [ -n "$libretro_name" ]; then
            printf "%s\n" "${libretro_name:?}" >>"${config_file:?}"
            print_step_point "${system_name:?}: ${libretro_name:?}"
        else
            print_step_point "${system_name:?}: (NO MATCH FOUND)"
        fi
    done
}

monitor_keys() {
    while IFS= read -rsn1 key </dev/tty; do
        keycode=$(printf '%d' "'$key")
        case "$keycode" in
        127 | 8 | 27) # DEL (127), Backspace (8), Escape (27)
            printf "\n\033[31m[ABORT]\033[0m Exit key pressed (DEL/BKSP/ESC).\n"
            kill 0
            ;;
        esac
    done
}

# Start in background and track its PID
monitor_keys &
KEYMON_PID=$!

# Clean up background job on script exit
trap 'kill $KEYMON_PID 2>/dev/null' EXIT

# Main
print_title "LibRetro Cheats Installer"

enable_cheats_cfg

print_step_header "Detecting installed systems"
detect_installed_systems
print_step_ok "Installed systems imported"

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
