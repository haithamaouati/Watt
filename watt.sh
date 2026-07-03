#!/usr/bin/env bash

# Author: Haitham Aouati
# GitHub: github.com/haithamaouati
# Watt - Wattpad user data scraper

# System Enforcement: Exit on error, unset variables, or pipe failures
set -euo pipefail

# Colors
nc="\e[0m"
bold="\e[1m"
underline="\e[4m"
bold_green="\e[1;32m"
bold_red="\e[1;31m"
bold_yellow="\e[1;33m"
orange='\033[38;5;214m'

# Dependency Verification
readonly REQUIRED_DEPS=("curl" "jq" "sed" "clear")
for cmd in "${REQUIRED_DEPS[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${bold_red}[ERROR]${nc} Missing critical dependency: $cmd\n" >&2
        exit 1
    fi
done

# Core Functions
reset_environment() {
    clear
    echo -e "${orange}"
    cat << 'EOF'
  _      __        __   __
 | | /| / / ___ _ / /_ / /_
 | |/ |/ / / _ `// __// __/
 |__/|__/  \_,_/ \__/ \__/
EOF
    echo -e "\n Watt${nc}pad user data scraper\n"
    echo -e " Author: Haitham Aouati"
    echo -e " GitHub: ${underline}github.com/haithamaouati${nc}\n"
}

extract_profile_data() {
    local user="$1"
    local target_url="https://www.wattpad.com/user/${user}/about"

    echo -e "Scraping Wattpad user data for ${orange}@${user}${nc}\n"

    # Network ingestion
    local html_source
    if ! html_source=$(curl -sS -L --max-time 15 -A "Mozilla/5.0 (compatible; Watt/1.0)" "$target_url"); then
        echo -e "${bold_red}[ERROR]${nc} Network connectivity failed.\n" >&2
        exit 1
    fi

    # Isolate inline JSON block (window.prefetched)
    local json_blob
    json_blob=$(echo "$html_source" | tr -d '\n' | grep -oP 'window\.prefetched\s*=\s*\K\{.*?\};' | sed 's/;$//')

    if [[ -z "$json_blob" ]]; then
        echo -e "${bold_red}[ERROR]${nc} Failed to extract source payload block. Verify username.\n" >&2
        exit 1
    fi

    # Structural confirmation
    if ! echo "$json_blob" | jq -e ". \"user.${user}\".data[0]" > /dev/null 2>&1; then
        echo -e "${bold_red}[ERROR]${nc} Unexpected payload schema encountered.\n" >&2
        exit 1
    fi

    # Parse user object
    local profile
    profile=$(echo "$json_blob" | jq ". \"user.${user}\".data[0]")

    # Helper: retrieve a single field with "N/A" fallback
    get_field() {
        echo "$profile" | jq -r ".$1 // \"N/A\""
    }

    # Render structured output details
    echo -e "${bold}Profile Information Summary${nc}\n"
    echo "Username:           $(get_field username)"
    echo "Avatar:             $(get_field avatar)"
    echo "Private:            $(get_field isPrivate)"
    echo "Background:         $(get_field backgroundUrl)"
    echo "Name:               $(get_field name)"
    echo "First Name:         $(get_field firstName)"
    echo "Last Name:          $(get_field lastName)"
    echo "Description:        $(get_field description)"
    echo "Gender:             $(get_field gender)"
    echo "Location:           $(get_field location)"
    echo "Created:            $(get_field createDate)"
    echo "Verified:           $(get_field verified)"
    echo "Ambassador:         $(get_field ambassador)"
    echo "Verified Email:     $(get_field verified_email)"
    echo "Highlight Color:    $(get_field highlight_colour)"
    echo "Website:            $(get_field website)"
    echo "Facebook:           $(get_field facebook)"
    echo "Smashwords:         $(get_field smashwords)"
    echo "Followers:          $(get_field numFollowers)"
    echo "Following:          $(get_field numFollowing)"
    echo "Stories Published:  $(get_field numStoriesPublished)"
    echo "Reading Lists:      $(get_field numLists)"
    echo "Allow Crawler:      $(get_field allowCrawler)"
    echo "HTML Enabled:       $(get_field html_enabled)"
    echo "Wattpad Squad:      $(get_field wattpad_squad)"
    echo "Is Staff:           $(get_field is_staff)"
    echo "Is Muted (user):    $(get_field isMuted)"
    echo "Safety - Muted:     $(get_field safety.isMuted)"
    echo "Safety - Blocked:   $(get_field safety.isBlocked)"
    echo "Following Request:  $(get_field followingRequest)"
    echo "Follower Request:   $(get_field followerRequest)"
    echo -e "\nURL: ${orange}https://www.wattpad.com/user/${user}/\n"
}

parse_arguments() {
    # Check if a positional parameter is completely missing
    if [[ $# -eq 0 ]]; then
        reset_environment
        echo -e "Usage: $0 ${orange}<username>${nc}\n" >&2
        exit 1
    fi

    local selected_username="$1"

    # Block attempts to pass flags or optional switches
    if [[ "$selected_username" =~ ^- ]]; then
        echo -e "${bold_red}[ERROR] Invalid input argument format: $selected_username${nc}\n" >&2
        exit 1
    fi

    reset_environment
    extract_profile_data "$selected_username"
}

# Entry Execution Trace
parse_arguments "$@"
