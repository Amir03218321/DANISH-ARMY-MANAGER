#!/data/data/com.termux/files/usr/bin/bash

# ======================================
#       DANISH ARMY TMP MANAGER
# ======================================

GREEN='\033[1;32m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
RESET='\033[0m'

TMP_DIR="/data/local/tmp"
CHANNEL="https://whatsapp.com/channel/0029Vb9KKE9EQIas4fPYVG1c"
TERMUX_BASH="/data/data/com.termux/files/usr/bin/bash"
TERMUX_PATH="/data/data/com.termux/files/usr/bin:/system/bin:/system/xbin"

FILES=()
SELECTED=""

# ONLINE UPDATE SETTINGS
# Set OWNER and REPO to the existing GitHub repository used for this tool.
GITHUB_OWNER="Amir03218321"
GITHUB_REPO="DANISH-ARMY-MANAGER"
GITHUB_BRANCH="main"
# Separate repository used ONLY for improvement suggestions (create it on GitHub).
IMPROVEMENT_REPO="DANIX-IMPROVEMENTS"
IMPROVEMENT_BRANCH="main"
# Set this to the deployed secure API proxy URL before publishing.
ACCESS_REQUEST_API="https://sparkling-star-daab.hahatechnology251.workers.dev/"
APP_VERSION="2.7.6"

# Music repository and private local storage.
MUSIC_REPO_ZIP_URL="https://github.com/Amir03218321/DANISH-ARMY-MUSIC/archive/refs/heads/main.zip"
MUSIC_DIR="$HOME/.danish-army-music"
MUSIC_ZIP_TEMP="$HOME/.danish-army-music-download.zip"
MUSIC_INSTALLED_VERSION_FILE="$MUSIC_DIR/.installed-version"
# Change this value only when you publish a NEW music pack.
# It is intentionally independent from APP_VERSION so normal app updates/logins
# do not trigger another music download.
MUSIC_PACK_VERSION="$APP_VERSION"
MUSIC_FILES=(
    maintenance.mp3
    new_update.mp3
    channel_gate.mp3
    main_menu.mp3
    file_control.mp3
    tmp_files.mp3
    panel_download.mp3
    driver_download.mp3
    update.mp3
    execute_file.mp3
    delete_file.mp3
    improvement_id.mp3
)

AUDIO_WARNING_SHOWN=0

stop_manager_audio() {
    if command -v termux-media-player >/dev/null 2>&1; then
        termux-media-player stop >/dev/null 2>&1 || true
    fi
}

play_manager_audio() {
    local audio_name="$1" audio_path="$MUSIC_DIR/$1" player_output player_status
    stop_manager_audio
    [[ -s "$audio_path" ]] || return 0
    if ! command -v termux-media-player >/dev/null 2>&1; then
        if (( AUDIO_WARNING_SHOWN == 0 )); then
            echo -e "${YELLOW}AUDIO PLAYER NOT AVAILABLE. Install Termux:API and run: pkg install termux-api${RESET}"
            AUDIO_WARNING_SHOWN=1
        fi
        return 0
    fi
    player_output="$(termux-media-player play "$audio_path" 2>&1)"
    player_status=$?
    if (( player_status != 0 )) && (( AUDIO_WARNING_SHOWN == 0 )); then
        echo -e "${YELLOW}AUDIO PLAYBACK FAILED: $audio_name${RESET}"
        [[ -n "$player_output" ]] && printf '%s\n' "$player_output"
        AUDIO_WARNING_SHOWN=1
    fi
}

prepare_manager_audio() {
    local audio_name missing=0 marker_version
    local extract_dir="$MUSIC_DIR/.extract-tmp"
    mkdir -p "$MUSIC_DIR" 2>/dev/null || return 0

    # Skip download only when all files exist AND this app/music-pack version
    # has already been installed. A new app version downloads the pack once.
    for audio_name in "${MUSIC_FILES[@]}"; do
        [[ -s "$MUSIC_DIR/$audio_name" ]] || missing=$((missing + 1))
    done
    marker_version="$(cat "$MUSIC_INSTALLED_VERSION_FILE" 2>/dev/null || true)"
    if (( missing == 0 )) && [[ "$marker_version" == "$MUSIC_PACK_VERSION" ]]; then
        return 0
    fi

    if [[ -z "$MUSIC_REPO_ZIP_URL" ]] ||
       ! command -v curl >/dev/null 2>&1 ||
       ! command -v unzip >/dev/null 2>&1; then
        return 0
    fi

    echo -e "${CYAN}DOWNLOADING MISSING DANISH ARMY MUSIC FILES...${RESET}"
    rm -f "$MUSIC_ZIP_TEMP"
    rm -rf "$extract_dir"
    mkdir -p "$extract_dir" || return 0

    local zip_url separator
    zip_url="$MUSIC_REPO_ZIP_URL"
    separator='?'
    [[ "$zip_url" == *\?* ]] && separator='&'
    zip_url="${zip_url}${separator}music_refresh=$(date +%s)"
    if ! curl -fsSL --retry 3 --connect-timeout 10 --max-time 180 \
        -H 'Cache-Control: no-cache' "$zip_url" -o "$MUSIC_ZIP_TEMP" ||
       [[ ! -s "$MUSIC_ZIP_TEMP" ]] ||
       ! unzip -tq "$MUSIC_ZIP_TEMP" >/dev/null 2>&1; then
        echo -e "${YELLOW}MUSIC DOWNLOAD FAILED. EXISTING SOUND FILES WERE KEPT.${RESET}"
        rm -f "$MUSIC_ZIP_TEMP"
        rm -rf "$extract_dir"
        return 0
    fi

    # Extract all MP3 entries by wildcard and flatten the GitHub ZIP folder.
    # This avoids fragile ZIP path/basename matching that caused false missing-file errors.
    if ! unzip -jo "$MUSIC_ZIP_TEMP" '*.mp3' -d "$extract_dir" >/dev/null 2>&1; then
        echo -e "${YELLOW}MUSIC ZIP EXTRACTION FAILED. EXISTING SOUND FILES WERE KEPT.${RESET}"
        rm -f "$MUSIC_ZIP_TEMP"
        rm -rf "$extract_dir"
        return 0
    fi

    local installed=0
    for audio_name in "${MUSIC_FILES[@]}"; do
        # Preserve every valid local file; install only missing/empty files.
        [[ -s "$MUSIC_DIR/$audio_name" ]] && continue
        if [[ -s "$extract_dir/$audio_name" ]] &&
           cp -f "$extract_dir/$audio_name" "$MUSIC_DIR/$audio_name"; then
            installed=$((installed + 1))
        fi
    done

    missing=0
    for audio_name in "${MUSIC_FILES[@]}"; do
        [[ -s "$MUSIC_DIR/$audio_name" ]] || missing=$((missing + 1))
    done

    if (( missing == 0 )); then
        printf '%s\n' "$MUSIC_PACK_VERSION" > "$MUSIC_INSTALLED_VERSION_FILE"
        echo -e "${GREEN}ALL ${#MUSIC_FILES[@]} SOUND FILES ARE READY.${RESET}"
    else
        echo -e "${YELLOW}SOUND PACK IS STILL MISSING $missing FILE(S). EXISTING FILES WERE KEPT.${RESET}"
    fi

    rm -f "$MUSIC_ZIP_TEMP"
    rm -rf "$extract_dir"
}


# REMOTE OWNER CONTROL (maintenance + mandatory minimum version)
CONTROL_URL="https://raw.githubusercontent.com/${GITHUB_OWNER}/${GITHUB_REPO}/${GITHUB_BRANCH}/control.txt"

# DRIVER DOWNLOAD SETTINGS
DRIVER_API="https://api.github.com/repos/Amir03218321/DANISH-DRIVERS/contents"
DRIVER_RAW="https://raw.githubusercontent.com/Amir03218321/DANISH-DRIVERS/main"
DRIVER_LIST_TEMP="$HOME/danish-driver-list.json"
DRIVER_TEMP="$HOME/danish-driver-download.tmp"
DRIVER_FILES=()

# PANEL DOWNLOAD SETTINGS
PANEL_API="https://api.github.com/repos/Amir03218321/DANISH-ARMY-PANEL/contents?ref=main"
PANEL_RAW="https://raw.githubusercontent.com/Amir03218321/DANISH-ARMY-PANEL/main"
PANEL_LIST_TEMP="$HOME/danish-panel-list.json"
PANEL_TEMP="$HOME/danish-panel-download.tmp"
PANEL_PRIVATE_DIR="$HOME/.danish-army-panels"
PANEL_MANIFEST="$PANEL_PRIVATE_DIR/panel-files.list"
PANEL_FILES=()

banner() {
    clear
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════╗"
    echo "║    DANISH ARMY TMP MANAGER         ║"
    echo "╚════════════════════════════════════╝"
    echo -e "${RESET}"
}

file_control_style() {
    echo
    echo -e "${GREEN}╔════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}║         FILE CONTROL PANEL         ║${RESET}"
    printf "${CYAN}║ VERSION: %-26s ║${RESET}\n" "$APP_VERSION"
    echo -e "${RED}╠════════════════════════════════════╣${RESET}"
    printf "${GREEN}║ SELECTED: %-25.25s ║${RESET}\n" "${SELECTED##*/}"
    echo -e "${YELLOW}╠════════════════════════════════════╣${RESET}"
    echo -e "${GREEN}║  1. EXECUTE FILE ▶                 ║${RESET}"
    echo -e "${CYAN}║  2. CHANGE PERMISSION              ║${RESET}"
    echo -e "${WHITE}║  3. VIEW FILE                      ║${RESET}"
    echo -e "${RED}║  4. DELETE FILE                    ║${RESET}"
    echo -e "${YELLOW}║  5. BACK TO FILE LIST              ║${RESET}"
    echo -e "${GREEN}╚════════════════════════════════════╝${RESET}"
    echo
}

main_menu_style() {
    echo
    echo -e "${GREEN}╔════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}║          MAIN CONTROL PANEL        ║${RESET}"
    printf "${CYAN}║ VERSION: %-26s ║${RESET}\n" "$APP_VERSION"
    echo -e "${RED}╠════════════════════════════════════╣${RESET}"
    echo -e "${GREEN}║  1. SHOW ALL TMP FILES             ║${RESET}"
    echo -e "${CYAN}║  2. SELECT FILE                    ║${RESET}"
    echo -e "${WHITE}║  3. REFRESH FILE LIST              ║${RESET}"
    echo -e "${YELLOW}║  4. JOIN WHATSAPP CHANNEL          ║${RESET}"
    echo -e "${GREEN}║  5. PANEL DOWNLOAD                 ║${RESET}"
    echo -e "${CYAN}║  6. DRIVER DOWNLOAD                ║${RESET}"
    echo -e "${RED}║  7. EXIT                           ║${RESET}"
    echo -e "${YELLOW}║  8. CHECK FOR UPDATES              ║${RESET}"
    echo -e "${CYAN}║  9. SEND IMPROVEMENT REQUEST       ║${RESET}"
    echo -e "${PURPLE}║ 10. OWNER INFO                     ║${RESET}"
    echo -e "${GREEN}╚════════════════════════════════════╝${RESET}"
    echo
}

pause() {
    echo
    read -r -p "Press ENTER to continue..."
}

quote_path() {
    local s="${1//\'/\'\\\'\'}"
    printf "'%s'" "$s"
}

open_channel() {
    if command -v termux-open-url >/dev/null 2>&1; then
        termux-open-url "$CHANNEL"
    elif command -v am >/dev/null 2>&1; then
        am start -a android.intent.action.VIEW -d "$CHANNEL"
    else
        echo "Open this channel manually: $CHANNEL"
    fi
}

open_owner_info() {
    local owner_url="https://wa.me/923247448664"
    echo -e "${CYAN}OPENING OWNER WHATSAPP CHAT...${RESET}"
    if command -v termux-open-url >/dev/null 2>&1; then
        termux-open-url "$owner_url" || echo "If WhatsApp did not open, visit: $owner_url"
    elif command -v am >/dev/null 2>&1; then
        am start -a android.intent.action.VIEW -d "$owner_url" || echo "If WhatsApp did not open, visit: $owner_url"
    else
        echo "Contact the owner here: $owner_url"
    fi
}

channel_gate() {
    local answer
    play_manager_audio "channel_gate.mp3"
    while true; do
        banner
        echo -e "${CYAN}OPENING WHATSAPP CHANNEL...${RESET}"
        open_channel
        echo
        echo -e "${YELLOW}HAVE YOU JOINED OUR CHANNEL?${RESET}"
        echo
        echo -e "${GREEN}1. YES${RESET}"
        echo -e "${RED}2. NO - OPEN CHANNEL AGAIN${RESET}"
        echo
        read -r -p "SELECT: " answer
        answer="$(printf '%s' "$answer" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')"
        case "$answer" in
            1|YES)
                echo -e "${GREEN}WELCOME TO DANISH ARMY!${RESET}"
                sleep 1
                return 0
                ;;
            2|NO)
                echo -e "${YELLOW}JOINING IS REQUIRED. PLEASE JOIN THE CHANNEL FIRST.${RESET}"
                sleep 1
                ;;
            *)
                echo -e "${RED}INVALID SELECTION! PLEASE CHOOSE YES OR NO.${RESET}"
                sleep 1
                ;;
        esac
    done
}


# GITHUB ACCESS APPROVAL GATE
# Owner approves a user by adding their generated ID to approved-users.txt
# in the repository root. Do not place passwords or private tokens here.
ACCESS_LIST_URL="https://raw.githubusercontent.com/${GITHUB_OWNER}/${GITHUB_REPO}/${GITHUB_BRANCH}/approved-users.txt"
ACCESS_REQUEST_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/issues/new"
DANIX_USER_DIR="${HOME}/.danix"
DANIX_USER_ID_FILE="${DANIX_USER_DIR}/user-id"
ACCESS_REQUEST_PENDING_FILE="${DANIX_USER_DIR}/access-request-pending"

open_github_url() {
    local url="$1"
    if command -v termux-open-url >/dev/null 2>&1; then
        termux-open-url "$url"
    elif command -v am >/dev/null 2>&1; then
        am start -a android.intent.action.VIEW -d "$url" >/dev/null 2>&1
    else
        echo "Open this URL manually: $url"
    fi
}

ensure_danix_user_id() {
    mkdir -p "$DANIX_USER_DIR"
    if [[ ! -s "$DANIX_USER_ID_FILE" ]]; then
        local generated_id
        generated_id="$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n' | tr 'a-f' 'A-F')"
        [[ -n "$generated_id" ]] || { echo "Could not create User ID."; exit 1; }
        printf '%s\n' "$generated_id" > "$DANIX_USER_ID_FILE"
        chmod 600 "$DANIX_USER_ID_FILE"
        play_manager_audio "improvement_id.mp3"
    fi
    DANIX_USER_ID="$(tr -d '\r\n' < "$DANIX_USER_ID_FILE")"
}

submit_access_request_once() {
    local approved_list="" response="" http_code="" curl_error="" payload=""
    [[ -n "${DANIX_USER_ID:-}" ]] || ensure_danix_user_id

    if ! [[ "$DANIX_USER_ID" =~ ^[A-F0-9]{16}$ ]]; then
        echo -e "${RED}INVALID OR EMPTY USER ID. REQUEST CANCELLED.${RESET}"
        return 1
    fi

    if ! command -v curl >/dev/null 2>&1; then
        printf '%s|%s\n' "$DANIX_USER_ID" "$APP_VERSION" > "$ACCESS_REQUEST_PENDING_FILE"
        chmod 600 "$ACCESS_REQUEST_PENDING_FILE"
        echo -e "${YELLOW}CURL IS MISSING. ACCESS REQUEST SAVED LOCALLY.${RESET}"
        echo "Install curl, then reopen the tool to retry."
        return 0
    fi

    # If GitHub confirms this exact ID is already approved, no request is needed.
    approved_list="$(curl -fsSL --retry 2 --connect-timeout 8 --max-time 15 \
        -H 'Cache-Control: no-cache' "${ACCESS_LIST_URL}?check=$(date +%s)" 2>/dev/null || true)"
    if printf '%s\n' "$approved_list" | tr -d '\r' | awk -F'|' -v id="$DANIX_USER_ID" \
        '$1 == id { found=1 } END { exit !found }'; then
        rm -f "$ACCESS_REQUEST_PENDING_FILE"
        echo -e "${GREEN}YOUR USER ID IS ALREADY APPROVED.${RESET}"
        return 0
    fi

    if [[ "$ACCESS_REQUEST_API" == *"YOUR-WORKER-NAME"* || -z "$ACCESS_REQUEST_API" ]]; then
        echo -e "${YELLOW}ACCESS REQUEST API IS NOT CONFIGURED.${RESET}"
        return 1
    fi

    # Keep a local pending record until the Worker explicitly confirms success.
    printf '%s|%s\n' "$DANIX_USER_ID" "$APP_VERSION" > "$ACCESS_REQUEST_PENDING_FILE"
    chmod 600 "$ACCESS_REQUEST_PENDING_FILE"

    # Worker integration uses JSON (the API's expected userId/appVersion payload).
    payload="$(printf '{"userId":"%s","appVersion":"%s"}' "$DANIX_USER_ID" "$APP_VERSION")"
    response="$(curl -sS --connect-timeout 10 --max-time 25 \
        -X POST "$ACCESS_REQUEST_API" \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json' \
        --data "$payload" \
        -w $'\nDANIX_HTTP_STATUS:%{http_code}' 2>&1)" || curl_error="$response"

    http_code="$(printf '%s\n' "$response" | sed -n 's/^DANIX_HTTP_STATUS://p' | tail -n 1)"
    response="$(printf '%s\n' "$response" | sed '/^DANIX_HTTP_STATUS:/d')"
    if [[ -z "$curl_error" && "$http_code" =~ ^2[0-9][0-9]$ ]] && \
       printf '%s' "$response" | grep -q '"ok"[[:space:]]*:[[:space:]]*true'; then
        rm -f "$ACCESS_REQUEST_PENDING_FILE"
        echo -e "${GREEN}ACCESS REQUEST SENT SUCCESSFULLY.${RESET}"
        echo -e "${WHITE}USER ID: ${DANIX_USER_ID}${RESET}"
        return 0
    fi

    echo -e "${YELLOW}REQUEST IS SAVED AS PENDING; IT WAS NOT MARKED AS SENT.${RESET}"
    echo -e "${WHITE}USER ID: ${DANIX_USER_ID}${RESET}"
    [[ -n "$http_code" ]] && echo "HTTP STATUS: $http_code"
    [[ -n "$curl_error" ]] && echo "Connection detail: $curl_error"
    [[ -n "$response" ]] && echo "API response: $response"
    echo "It will retry on the next launch or when you choose Check Approval Again."
    return 0
}

github_access_check() {
    local approved_list approved_id expiry now
    [[ "${DANIX_USER_ID:-}" =~ ^[A-F0-9]{16}$ ]] || return 1
    approved_list="$(curl -fsSL --retry 2 --connect-timeout 8 --max-time 15 \
        -H 'Cache-Control: no-cache' "${ACCESS_LIST_URL}?check=$(date +%s)" 2>/dev/null)" || return 2
    now="$(date +%s)"
    while IFS='|' read -r approved_id expiry; do
        approved_id="$(printf '%s' "$approved_id" | tr -d '\r' | sed 's/[[:space:]]//g')"
        [[ -n "$approved_id" && "$approved_id" == "$DANIX_USER_ID" ]] || continue
        expiry="$(printf '%s' "${expiry:-0}" | tr -d '\r' | sed 's/[[:space:]]//g')"
        [[ -z "$expiry" ]] && expiry=0
        [[ "$expiry" =~ ^[0-9]+$ ]] || return 1
        if (( expiry == 0 || expiry > now )); then return 0; fi
        return 1
    done <<< "$approved_list"
    return 1
}

github_access_gate() {
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}CURL IS REQUIRED FOR GITHUB ACCESS CHECK.${RESET}"
        echo "Install it with: pkg install curl -y"
        exit 1
    fi

    ensure_danix_user_id

    if [[ -s "$ACCESS_REQUEST_PENDING_FILE" ]]; then
        echo -e "${CYAN}RETRYING YOUR SAVED ACCESS REQUEST...${RESET}"
        submit_access_request_once
        sleep 1
    fi

    while true; do
        banner
        echo -e "${CYAN}             GITHUB ACCESS CHECK${RESET}"
        echo
        if github_access_check; then
            echo -e "${GREEN}ACCESS APPROVED. WELCOME TO DANIX TERMINAL.${RESET}"
            sleep 1
            return 0
        else
            local check_result=$?
            if [[ "$check_result" -eq 2 ]]; then
                echo -e "${RED}GITHUB COULD NOT BE REACHED.${RESET}"
                echo "Check your internet connection and try again."
            else
                echo -e "${YELLOW}YOUR ACCESS IS NOT APPROVED YET.${RESET}"
            fi
        fi

        echo
        echo -e "${WHITE}YOUR USER ID: ${GREEN}${DANIX_USER_ID}${RESET}"
        echo
        echo -e "${GREEN}1. SEND ACCESS REQUEST${RESET}"
        echo -e "${CYAN}2. CHECK APPROVAL AGAIN${RESET}"
        echo -e "${RED}3. EXIT${RESET}"
        echo
        read -r -p "SELECT: " access_choice
        case "$access_choice" in
            1)
                submit_access_request_once
                pause
                ;;
            2)
                echo "Checking approval..."
                if [[ -s "$ACCESS_REQUEST_PENDING_FILE" ]]; then
                    echo -e "${CYAN}RETRYING YOUR SAVED ACCESS REQUEST...${RESET}"
                    submit_access_request_once
                    pause
                fi
                ;;
            3)
                echo "Access request closed."
                exit 0
                ;;
            *)
                echo -e "${RED}INVALID OPTION.${RESET}"
                pause
                ;;
        esac
    done
}



url_encode() {
    local LC_ALL=C
    local input="$1" output="" c hex i
    for ((i=0; i<${#input}; i++)); do
        c="${input:i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-]) output+="$c" ;;
            ' ') output+="%20" ;;
            *)
                printf -v hex '%%%02X' "'$c"
                output+="$hex"
                ;;
        esac
    done
    printf '%s' "$output"
}

send_improvement_request() {
    banner
    echo -e "${CYAN}          DANIX IMPROVEMENT REQUEST${RESET}"
    echo
    echo "Write your idea or improvement request below."
    echo "Do not include passwords, private keys, or personal information."
    echo
    printf "Improvement title: "
    local title
    IFS= read -r title
    if [[ -z "${title//[[:space:]]/}" ]]; then
        echo -e "${RED}TITLE CANNOT BE EMPTY.${RESET}"
        pause
        return
    fi

    echo
    echo "Describe the improvement. Finish with an empty line:"
    local body="" line
    while IFS= read -r line; do
        [[ -z "$line" ]] && break
        body+="${line}"$'\\n'
    done
    if [[ -z "${body//[[:space:]]/}" ]]; then
        echo -e "${RED}DESCRIPTION CANNOT BE EMPTY.${RESET}"
        pause
        return
    fi

    local issue_url encoded_title encoded_body
    encoded_title="$(url_encode "$title")"
    encoded_body="$(url_encode "DANIX User ID: ${DANIX_USER_ID}\n\nImprovement:\n${body}")"
    issue_url="https://github.com/${GITHUB_OWNER}/${IMPROVEMENT_REPO}/issues/new?title=${encoded_title}&body=${encoded_body}"

    echo
    echo -e "${GREEN}OPENING THE SEPARATE IMPROVEMENT REPOSITORY...${RESET}"
    echo "Review the prefilled text and press Submit on GitHub."
    open_github_url "$issue_url"
    pause
}


root_check() {
    if ! command -v su >/dev/null 2>&1 || ! su -c "test -d '$TMP_DIR'"; then
        echo -e "${RED}ROOT ACCESS REQUIRED OR ROOT MANAGER UNAVAILABLE!${RESET}"
        exit 1
    fi
}

refresh_files() {
    mapfile -d '' -t FILES < <(su -c "find '$TMP_DIR' -maxdepth 1 -type f -print0" 2>/dev/null)
}

show_files() {
    play_manager_audio "tmp_files.mp3"
    refresh_files
    echo
    echo -e "${CYAN}══════════ TMP FILE DATABASE ══════════${RESET}"
    echo -e "${WHITE}DANISH ARMY MANAGER VERSION: ${APP_VERSION}${RESET}"
    if [ "${#FILES[@]}" -eq 0 ]; then
        echo -e "${YELLOW}NO FILES FOUND!${RESET}"
        return
    fi
    for i in "${!FILES[@]}"; do
        echo
        echo -e "${GREEN}[$((i+1))]${RESET} ${WHITE}${FILES[$i]##*/}${RESET}"
    done
    echo
    echo -e "${CYAN}TOTAL FILES: ${#FILES[@]}${RESET}"
}

select_file() {
    show_files
    [ "${#FILES[@]}" -gt 0 ] || return 1
    echo
    read -r -p "ENTER FILE NUMBER: " number
    if ! [[ "$number" =~ ^[0-9]+$ ]] || [ "$number" -lt 1 ] || [ "$number" -gt "${#FILES[@]}" ]; then
        echo -e "${RED}INVALID FILE SELECTION!${RESET}"
        return 1
    fi
    SELECTED="${FILES[$((number-1))]}"
    if ! su -c "test -f $(quote_path "$SELECTED")"; then
        echo -e "${RED}FILE NO LONGER EXISTS!${RESET}"
        return 1
    fi
}

view_file() {
    echo
    echo -e "${CYAN}FILE PREVIEW${RESET}"
    echo -e "${WHITE}FILE: ${SELECTED##*/}${RESET}"
    echo
    su -c "sed -n '1,60p' $(quote_path "$SELECTED")"
    echo
    echo -e "${YELLOW}FIRST 60 LINES SHOWN${RESET}"
}

execute_file() {
    play_manager_audio "execute_file.mp3"
    if [[ "$SELECTED" != *.sh ]]; then
        echo -e "${RED}ONLY .SH FILES ARE SUPPORTED!${RESET}"
        return
    fi
    if ! su -c "test -r $(quote_path "$SELECTED")"; then
        echo -e "${RED}FILE CANNOT BE READ!${RESET}"
        return
    fi
    if ! su -c "test -x $(quote_path "$TERMUX_BASH")"; then
        echo -e "${RED}TERMUX BASH NOT FOUND OR NOT EXECUTABLE!${RESET}"
        return
    fi
    echo
    echo -e "${RED}WARNING: THIS FILE WILL RUN WITH ROOT PRIVILEGES!${RESET}"
    echo -e "${YELLOW}Only run scripts you personally trust and have inspected.${RESET}"
    view_file
    read -r -p "TYPE YES TO CONFIRM: " confirm
    if [ "$confirm" = "YES" ]; then
        local dir="${SELECTED%/*}"
        local base="${SELECTED##*/}"
        su -c "cd $(quote_path "$dir") && export PATH=$(quote_path "$TERMUX_PATH") && exec $(quote_path "$TERMUX_BASH") $(quote_path "$base")"
        local result=$?
        if [ "$result" -eq 0 ]; then
            echo -e "${GREEN}EXECUTION COMPLETED SUCCESSFULLY!${RESET}"
        else
            echo -e "${RED}EXECUTION FAILED! EXIT CODE: $result${RESET}"
        fi
    else
        echo -e "${YELLOW}EXECUTION CANCELLED!${RESET}"
    fi
}

permission_menu() {
    echo
    echo -e "${CYAN}════════ PERMISSION CONTROL ════════${RESET}"
    echo -e "${GREEN}1. 700 - OWNER ONLY${RESET}"
    echo -e "${GREEN}2. 755 - OWNER WRITE, ALL EXECUTE${RESET}"
    echo -e "${WHITE}3. BACK${RESET}"
    echo
    read -r -p "SELECT PERMISSION: " perm
    case "$perm" in
        1) mode="700" ;;
        2) mode="755" ;;
        3) return ;;
        *) echo -e "${RED}INVALID PERMISSION!${RESET}"; return ;;
    esac
    if su -c "chmod $mode $(quote_path "$SELECTED")"; then
        echo -e "${GREEN}PERMISSION CHANGED: $mode${RESET}"
    else
        echo -e "${RED}PERMISSION CHANGE FAILED!${RESET}"
    fi
}

delete_file() {
    play_manager_audio "delete_file.mp3"
    echo
    echo -e "${RED}SELECTED FILE: ${SELECTED##*/}${RESET}"
    read -r -p "TYPE DELETE TO CONFIRM: " confirm
    if [ "$confirm" = "DELETE" ]; then
        if su -c "rm -f $(quote_path "$SELECTED")"; then
            echo -e "${GREEN}FILE DELETED SUCCESSFULLY!${RESET}"
            SELECTED=""
        else
            echo -e "${RED}DELETE FAILED!${RESET}"
        fi
    else
        echo -e "${YELLOW}DELETE CANCELLED!${RESET}"
    fi
}

download_repo_script() {
    local kind="$1" api="$2" raw="$3" list_temp="$4" temp_file="$5"
    local -n names_ref="$6"
    local label="$7"

    banner
    echo -e "${GREEN}╔════════════════════════════════════╗${RESET}"
    printf "${YELLOW}║ %-34s ║${RESET}\n" "$label"
    echo -e "${GREEN}╚════════════════════════════════════╝${RESET}"

    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}CURL NOT FOUND! Install: pkg install curl -y${RESET}"
        pause
        return
    fi

    echo -e "${CYAN}FETCHING FILE LIST FROM GITHUB...${RESET}"
    rm -f "$list_temp"
    if ! curl -fsSL --retry 2 -H "Accept: application/vnd.github+json" "$api" -o "$list_temp"; then
        echo -e "${RED}COULD NOT FETCH FILE LIST!${RESET}"
        rm -f "$list_temp"
        pause
        return
    fi

    mapfile -t names_ref < <(grep -oE '"name"[[:space:]]*:[[:space:]]*"[^"]+\.sh"' "$list_temp" | sed -E 's/.*"([^"]+)"$/\1/' | sort)
    rm -f "$list_temp"

    if [ "${#names_ref[@]}" -eq 0 ]; then
        echo -e "${RED}NO $kind FILES FOUND!${RESET}"
        pause
        return
    fi

    echo
    for i in "${!names_ref[@]}"; do
        printf "${YELLOW}[%02d]${RESET} ${WHITE}%s${RESET}\n" "$((i+1))" "${names_ref[$i]}"
    done
    echo
    printf "TOTAL %s FILES: %s\n" "$kind" "${#names_ref[@]}"
    read -r -p "SELECT $kind NUMBER: " chosen
    if ! [[ "$chosen" =~ ^[0-9]+$ ]] || [ "$chosen" -lt 1 ] || [ "$chosen" -gt "${#names_ref[@]}" ]; then
        echo -e "${RED}INVALID SELECTION!${RESET}"
        pause
        return
    fi

    local filename="${names_ref[$((chosen-1))]}"
    local dest
    if [[ "$kind" == "PANEL" ]]; then
        dest="$PANEL_PRIVATE_DIR/$filename"
    else
        dest="$TMP_DIR/$filename"
    fi
    local encoded="${filename//%/%25}"
    encoded="${encoded// /%20}"
    encoded="${encoded//+/%2B}"
    encoded="${encoded//(/%28}"
    encoded="${encoded//)/%29}"
    encoded="${encoded//#/%23}"

    echo
    echo -e "${YELLOW}SELECTED: $filename${RESET}"
    if [[ "$kind" == "PANEL" ]]; then
        if [[ -e "$dest" ]]; then
            read -r -p "Already exists in private storage. Type YES to overwrite: " overwrite
            [ "$overwrite" = "YES" ] || { echo "Download cancelled."; pause; return; }
        fi
    elif su -c "test -e $(quote_path "$dest")"; then
        read -r -p "Already exists. Type YES to overwrite: " overwrite
        [ "$overwrite" = "YES" ] || { echo "Download cancelled."; pause; return; }
    fi

    rm -f "$temp_file"
    if ! curl -fL --retry 2 "$raw/$encoded" -o "$temp_file" || [ ! -s "$temp_file" ]; then
        echo -e "${RED}DOWNLOAD FAILED OR EMPTY FILE!${RESET}"
        rm -f "$temp_file"
        pause
        return
    fi

    echo
    echo -e "${YELLOW}Review downloaded script before executing it.${RESET}"
    local install_ok=0
    if [[ "$kind" == "PANEL" ]]; then
        if mkdir -p "$PANEL_PRIVATE_DIR" &&
           install -m 600 "$temp_file" "$dest"; then
            touch "$PANEL_MANIFEST"
            if ! grep -Fqx -- "$filename" "$PANEL_MANIFEST" 2>/dev/null; then
                printf '%s\n' "$filename" >> "$PANEL_MANIFEST"
            fi
        fi
        if [[ -s "$dest" ]] && grep -Fqx -- "$filename" "$PANEL_MANIFEST" 2>/dev/null; then
            install_ok=1
            echo -e "${GREEN}PANEL SAVED IN TERMUX PRIVATE STORAGE.${RESET}"
            echo "FILE: $filename"
            echo "The private original stays saved. A TMP copy is restored at startup and removed on exit."
        fi
    elif su -c "mkdir -p $(quote_path "$TMP_DIR") && cp $(quote_path "$temp_file") $(quote_path "$dest") && chmod 700 $(quote_path "$dest")"; then
        install_ok=1
        echo -e "${GREEN}$kind DOWNLOAD SUCCESS!${RESET}"
        echo "FILE: $filename"
        echo "PERMISSION: 700"
    fi
    if [[ "$install_ok" -eq 0 ]]; then
        echo -e "${RED}INSTALLATION FAILED!${RESET}"
    fi
    rm -f "$temp_file"
    pause
}

read_panel_manifest() {
    [[ -f "$PANEL_MANIFEST" ]] || return 0
    # Normalize CRLF and ignore unsafe/empty entries. Manifest stores basenames only.
    local filename
    while IFS= read -r filename || [[ -n "$filename" ]]; do
        filename="${filename%$'\r'}"
        [[ -n "$filename" && "$filename" != */* && "$filename" != "." && "$filename" != ".." ]] || continue
        printf '%s\n' "$filename"
    done < "$PANEL_MANIFEST"
}

stage_private_panels_to_tmp() {
    [[ -d "$PANEL_PRIVATE_DIR" && -f "$PANEL_MANIFEST" ]] || return 0
    local filename source dest staged=0 failed=0
    while IFS= read -r filename; do
        source="$PANEL_PRIVATE_DIR/$filename"
        dest="$TMP_DIR/$filename"
        [[ -s "$source" ]] || continue
        if su -c "mkdir -p $(quote_path "$TMP_DIR") && cp -p -f $(quote_path "$source") $(quote_path "$dest") && chmod 755 $(quote_path "$dest")"; then
            staged=$((staged + 1))
        else
            echo -e "${RED}COULD NOT COPY PANEL INTO TMP: $filename${RESET}"
            failed=1
        fi
    done < <(read_panel_manifest)
    if (( staged > 0 )); then
        echo -e "${GREEN}RESTORED $staged PANEL FILE(S) FROM PRIVATE STORAGE TO TMP.${RESET}"
    fi
    (( failed == 0 ))
}

cleanup_staged_panels() {
    [[ -f "$PANEL_MANIFEST" ]] || return 0
    local filename dest removed=0 failed=0
    while IFS= read -r filename; do
        dest="$TMP_DIR/$filename"
        if su -c "rm -f $(quote_path "$dest")" >/dev/null 2>&1; then
            removed=$((removed + 1))
        else
            failed=1
        fi
    done < <(read_panel_manifest)
    if (( removed > 0 )); then
        echo -e "${GREEN}CLEANUP: REMOVED $removed REGISTERED PANEL COPY/COPIES FROM TMP.${RESET}"
    fi
    (( failed == 0 ))
}

panel_download() {
    play_manager_audio "panel_download.mp3"
    download_repo_script "PANEL" "$PANEL_API" "$PANEL_RAW" "$PANEL_LIST_TEMP" "$PANEL_TEMP" PANEL_FILES "PANEL DOWNLOADER"
}

driver_download() {
    play_manager_audio "driver_download.mp3"
    download_repo_script "DRIVER" "$DRIVER_API" "$DRIVER_RAW" "$DRIVER_LIST_TEMP" "$DRIVER_TEMP" DRIVER_FILES "DRIVER DOWNLOAD"
}

file_control() {
    while [ -n "$SELECTED" ]; do
        play_manager_audio "file_control.mp3"
        if ! su -c "test -f $(quote_path "$SELECTED")"; then
            echo -e "${RED}FILE NOT FOUND!${RESET}"
            SELECTED=""
            break
        fi
        file_control_style
        read -r -p "SELECT ACTION: " action
        case "$action" in
            1) execute_file ;;
            2) permission_menu ;;
            3) view_file ;;
            4) delete_file ;;
            5) SELECTED="" ;;
            *) echo -e "${RED}INVALID OPTION!${RESET}" ;;
        esac
    done
}


check_for_updates() {
    play_manager_audio "update.mp3"
    banner
    echo -e "${CYAN}CHECKING ONLINE UPDATES...${RESET}"

    if [[ "$GITHUB_OWNER" == "YOUR_GITHUB_USERNAME" || "$GITHUB_REPO" == "YOUR_EXISTING_REPOSITORY" ]]; then
        echo -e "${RED}GITHUB SETTINGS ARE NOT CONFIGURED.${RESET}"
        echo "Set GITHUB_OWNER and GITHUB_REPO near the top of this script."
        pause
        return
    fi
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}CURL NOT FOUND. RUN: pkg install curl -y${RESET}"
        pause
        return
    fi

    local base="https://raw.githubusercontent.com/$GITHUB_OWNER/$GITHUB_REPO/$GITHUB_BRANCH"
    local version_tmp script_tmp dest backup remote_version embedded_version
    version_tmp="$(mktemp)" || return
    script_tmp="$(mktemp)" || { rm -f "$version_tmp"; return; }
    dest="${PREFIX:-/data/data/com.termux/files/usr}/bin/danish-army-manager"
    backup="$dest.backup"

    if ! curl -fsSL --retry 2 "$base/VERSION" -o "$version_tmp"; then
        echo -e "${RED}COULD NOT READ VERSION FROM GITHUB.${RESET}"
        rm -f "$version_tmp" "$script_tmp"; pause; return
    fi
    remote_version="$(tr -d '[:space:]' < "$version_tmp")"
    if ! [[ "$remote_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}INVALID VERSION FILE ON GITHUB.${RESET}"
        rm -f "$version_tmp" "$script_tmp"; pause; return
    fi

    echo -e "${WHITE}INSTALLED VERSION: $APP_VERSION${RESET}"
    echo -e "${WHITE}ONLINE VERSION:    $remote_version${RESET}"

    local -a current_parts remote_parts
    IFS=. read -r -a current_parts <<< "$APP_VERSION"
    IFS=. read -r -a remote_parts <<< "$remote_version"
    local newer=0 i current online
    for i in 0 1 2; do
        current="${current_parts[$i]:-0}"
        online="${remote_parts[$i]:-0}"
        if (( 10#$online > 10#$current )); then newer=1; break
        elif (( 10#$online < 10#$current )); then break
        fi
    done
    if [[ "$newer" -eq 0 ]]; then
        echo -e "${GREEN}YOU ARE USING THE LATEST VERSION.${RESET}"
        rm -f "$version_tmp" "$script_tmp"; pause; return
    fi

    play_manager_audio "new_update.mp3"
    echo -e "${YELLOW}NEW VERSION FOUND: $remote_version${RESET}"
    if ! curl -fsSL --retry 2 "$base/danish-army-manager.sh" -o "$script_tmp" ||
       [[ ! -s "$script_tmp" ]] || ! bash -n "$script_tmp"; then
        echo -e "${RED}DOWNLOAD OR SHELL CHECK FAILED. NO CHANGES MADE.${RESET}"
        rm -f "$version_tmp" "$script_tmp"; pause; return
    fi

    # Normalize Windows CRLF line endings and tolerate harmless spaces around
    # the assignment. Keep the version comparison strict after extraction.
    embedded_version="$(tr -d '\r' < "$script_tmp" | sed -nE 's/^[[:space:]]*APP_VERSION[[:space:]]*=[[:space:]]*"([0-9]+\.[0-9]+\.[0-9]+)"[[:space:]]*$/\1/p' | head -n 1 | tr -d '[:space:]')"
    if [[ -z "$embedded_version" ]]; then
        echo -e "${RED}APP_VERSION COULD NOT BE READ FROM DOWNLOADED SCRIPT. UPDATE CANCELLED.${RESET}"
        rm -f "$version_tmp" "$script_tmp"; pause; return
    fi
    if [[ "$embedded_version" != "$remote_version" ]]; then
        echo -e "${RED}VERSION MISMATCH: VERSION FILE=$remote_version, SCRIPT=$embedded_version. UPDATE CANCELLED.${RESET}"
        rm -f "$version_tmp" "$script_tmp"; pause; return
    fi
    if [[ ! -f "$dest" ]]; then
        echo -e "${RED}INSTALLED MANAGER NOT FOUND: $dest${RESET}"
        rm -f "$version_tmp" "$script_tmp"; pause; return
    fi
    if ! cp -p "$dest" "$backup"; then
        echo -e "${RED}BACKUP FAILED. UPDATE CANCELLED.${RESET}"
        rm -f "$version_tmp" "$script_tmp"; pause; return
    fi
    if install -m 700 "$script_tmp" "$dest"; then
        rm -f "$backup"
        echo -e "${GREEN}UPDATE INSTALLED SUCCESSFULLY.${RESET}"
        # Clear only after the new script is installed successfully.
        # Preserve the normal exit-time staged-panel cleanup behavior.
        if [[ "$PANEL_PRIVATE_DIR" == "$HOME/.danish-army-panels" ]]; then
            rm -rf -- "$PANEL_PRIVATE_DIR"
            if [[ ! -e "$PANEL_PRIVATE_DIR" ]]; then
                echo -e "${GREEN}TERMUX PRIVATE PANEL DOWNLOADS CLEARED.${RESET}"
            else
                echo -e "${YELLOW}COULD NOT CLEAR PRIVATE PANEL DOWNLOADS.${RESET}"
            fi
        fi
        # Remove every entry inside /data/local/tmp, but keep/recreate the directory
        # because the manager and Android tools expect this path to exist.
        if su -c "if [ -d '$TMP_DIR' ]; then find '$TMP_DIR' -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +; else mkdir -p '$TMP_DIR'; fi"; then
            echo -e "${GREEN}ALL CONTENTS INSIDE $TMP_DIR CLEARED AFTER UPDATE.${RESET}"
        else
            echo -e "${RED}TMP CLEANUP FAILED. CHECK ROOT PERMISSION.${RESET}"
        fi
        echo -e "${CYAN}CLOSE AND REOPEN THE TOOL TO USE VERSION $remote_version.${RESET}"
    else
        mv -f "$backup" "$dest"
        echo -e "${RED}UPDATE FAILED. PREVIOUS VERSION RESTORED.${RESET}"
    fi
    rm -f "$version_tmp" "$script_tmp"
    pause
}


# Compare three-part numeric versions: returns 0 when $1 is >= $2.
version_at_least() {
    local left="$1" right="$2" i a b
    local -a left_parts right_parts
    [[ "$left" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$right" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 2
    IFS=. read -r -a left_parts <<< "$left"
    IFS=. read -r -a right_parts <<< "$right"
    for i in 0 1 2; do
        a="${left_parts[$i]}"; b="${right_parts[$i]}"
        a="$((10#$a))"; b="$((10#$b))"
        (( a > b )) && return 0
        (( a < b )) && return 1
    done
    return 0
}

# Block startup during maintenance or when this installation is below MIN_VERSION.
# This check requires internet access; if GitHub cannot be checked, access is denied.
remote_control_gate() {
    local control_tmp maintenance min_version message key value
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}CURL IS REQUIRED TO CHECK OWNER CONTROL SETTINGS.${RESET}"
        echo "Install it with: pkg install curl -y"
        exit 1
    fi

    control_tmp="$(mktemp)" || exit 1
    while true; do
        if ! curl -fsSL --connect-timeout 8 --max-time 15 --retry 1 \
            -H 'Cache-Control: no-cache' "${CONTROL_URL}?check=$(date +%s)" -o "$control_tmp"; then
            rm -f "$control_tmp"
            echo -e "${RED}OWNER CONTROL CHECK FAILED. MANAGER ACCESS IS BLOCKED.${RESET}"
            echo "Check your internet connection or ask the owner to restore control.txt."
            exit 1
        fi

        maintenance="$(sed -n 's/^MAINTENANCE=//p' "$control_tmp" | head -n 1 | tr -d '\r[:space:]')"
        min_version="$(sed -n 's/^MIN_VERSION=//p' "$control_tmp" | head -n 1 | tr -d '\r[:space:]')"
        message="$(sed -n 's/^MESSAGE=//p' "$control_tmp" | head -n 1 | tr -d '\r')"

        if [[ "$maintenance" != "ON" && "$maintenance" != "OFF" ]] || \
           ! [[ "$min_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            rm -f "$control_tmp"
            echo -e "${RED}INVALID OWNER CONTROL FILE. MANAGER ACCESS IS BLOCKED.${RESET}"
            exit 1
        fi

        if [[ "$maintenance" == "ON" ]]; then
            play_manager_audio "maintenance.mp3"
            echo -e "${YELLOW}DANISH ARMY MANAGER IS TEMPORARILY UNDER MAINTENANCE.${RESET}"
            [[ -n "$message" ]] && echo "$message"
            echo "Please try again later."
            rm -f "$control_tmp"
            exit 0
        fi

        if version_at_least "$APP_VERSION" "$min_version"; then
            rm -f "$control_tmp"
            return 0
        fi

        banner
        echo -e "${RED}MANDATORY UPDATE REQUIRED.${RESET}"
        echo -e "${WHITE}INSTALLED VERSION: $APP_VERSION${RESET}"
        echo -e "${WHITE}REQUIRED VERSION:  $min_version${RESET}"
        [[ -n "$message" ]] && echo "$message"
        echo
        echo "1. UPDATE NOW"
        echo "2. EXIT"
        read -r -p "SELECT: " update_choice
        case "$update_choice" in
            1)
                check_for_updates
                ;;
            2)
                rm -f "$control_tmp"
                exit 0
                ;;
            *)
                echo -e "${RED}INVALID OPTION.${RESET}"
                sleep 1
                ;;
        esac
    done
}

main_menu() {
    while true; do
        play_manager_audio "main_menu.mp3"
        banner
        main_menu_style
        read -r -p "SELECT OPTION: " option
        case "$option" in
            1) banner; show_files; pause ;;
            2) if select_file; then file_control; fi; pause ;;
            3) refresh_files; echo -e "${GREEN}FILE LIST REFRESHED!${RESET}"; pause ;;
            4) open_channel; pause ;;
            5) panel_download ;;
            6) driver_download ;;
            7) stop_manager_audio; cleanup_staged_panels; echo -e "${YELLOW}DANISH ARMY TMP MANAGER CLOSED!${RESET}"; exit 0 ;;
            8) check_for_updates ;;
            9) send_improvement_request ;;
            10) open_owner_info; pause ;;
            *) echo -e "${RED}INVALID OPTION!${RESET}"; pause ;;
        esac
    done
}

prepare_manager_audio
remote_control_gate
ensure_danix_user_id
channel_gate
github_access_gate
root_check
trap cleanup_staged_panels EXIT
if ! stage_private_panels_to_tmp; then
    echo -e "${RED}PANEL RESTORE FAILED. ORIGINAL PRIVATE COPY WAS KEPT.${RESET}"
    exit 1
fi
main_menu
