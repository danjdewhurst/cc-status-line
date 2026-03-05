#!/bin/bash

# Status line - model, git branch, cwd, context usage, cost
# Catppuccin theme (https://catppuccin.com)

# Configuration
CATPPUCCIN_FLAVOR='frappe' # Catppuccin flavor: 'latte', 'frappe', 'macchiato', 'mocha'
CURRENCY='$'              # Currency symbol (e.g., '$', '€', '£', '¥')
CURRENCY_CODE='USD'       # ISO 4217 code for API lookup (e.g., 'USD', 'GBP', 'EUR', 'JPY')
EXCHANGE_RATE=1           # Fallback rate if API unavailable

# Cache settings
CACHE_DIR="${HOME}/.cache/cc-status-line"
CACHE_FILE="${CACHE_DIR}/exchange-rate.json"
CACHE_MAX_AGE=86400       # 24 hours in seconds

# Get exchange rate (from cache or API)
get_exchange_rate() {
    # Use fallback if no currency code set or set to USD
    [ -z "$CURRENCY_CODE" ] || [ "$CURRENCY_CODE" = "USD" ] && echo "1" && return

    # Check if cache exists and is fresh
    if [ -f "$CACHE_FILE" ]; then
        cache_age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0) ))
        if [ "$cache_age" -lt "$CACHE_MAX_AGE" ]; then
            cached_rate=$(jq -r --arg code "$CURRENCY_CODE" '.rates[$code] // empty' "$CACHE_FILE" 2>/dev/null)
            [ -n "$cached_rate" ] && echo "$cached_rate" && return
        fi
    fi

    # Fetch fresh rate (in background to avoid blocking)
    mkdir -p "$CACHE_DIR"
    rate=$(curl -sf --max-time 2 "https://api.frankfurter.app/latest?from=USD&to=${CURRENCY_CODE}" 2>/dev/null)
    if [ -n "$rate" ]; then
        echo "$rate" > "$CACHE_FILE"
        jq -r --arg code "$CURRENCY_CODE" '.rates[$code] // empty' <<< "$rate" 2>/dev/null && return
    fi

    # Fallback to configured rate
    echo "$EXCHANGE_RATE"
}

data=$(cat)

# Single jq call - extract all values at once (tab-separated)
IFS=$'\t' read -r model cwd max_ctx used_pct cost_usd <<< "$(echo "$data" | jq -r '[
    (.model.display_name // .model.id // "unknown"),
    (.workspace.current_dir // ""),
    (.context_window.context_window_size // 200000),
    (.context_window.used_percentage // ""),
    (.cost.total_cost_usd // 0)
] | @tsv')"

# Get Claude Code version
cc_version=$(claude --version 2>/dev/null | awk '{print $1}')

# Folder name from path
folder="${cwd##*/}"
[ -z "$folder" ] && folder="?"

# Git: branch + dirty status (fast combined check)
branch=""
dirty=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    [ -z "$branch" ] && branch=$(git rev-parse --short HEAD 2>/dev/null)

    # Truncate long branches (max 20 chars)
    if [ "${#branch}" -gt 20 ]; then
        branch="${branch:0:19}…"
    fi

    # Check for uncommitted changes (fast: just check if output exists)
    if [ -n "$(git status --porcelain 2>/dev/null | head -1)" ]; then
        dirty="●"
    fi
fi

# Catppuccin colors (24-bit true color)
# Set colors based on selected flavor
flavor=$(echo "$CATPPUCCIN_FLAVOR" | tr '[:upper:]' '[:lower:]')
case "$flavor" in
    latte)
        BLUE='\033[38;2;30;102;245m'       # #1e66f5
        RED='\033[38;2;210;15;57m'         # #d20f39
        TEAL='\033[38;2;23;146;153m'       # #179299
        MAUVE='\033[38;2;136;57;239m'      # #8839ef
        LAVENDER='\033[38;2;114;135;253m'  # #7287fd
        PEACH='\033[38;2;254;100;11m'      # #fe640b
        GREEN='\033[38;2;64;160;43m'       # #40a02b
        OVERLAY='\033[38;2;156;160;176m'   # #9ca0b0
        SUBTEXT='\033[38;2;108;111;133m'   # #6c6f85
        ;;
    macchiato)
        BLUE='\033[38;2;138;173;244m'      # #8aadf4
        RED='\033[38;2;237;135;150m'       # #ed8796
        TEAL='\033[38;2;139;213;202m'      # #8bd5ca
        MAUVE='\033[38;2;198;160;246m'     # #c6a0f6
        LAVENDER='\033[38;2;183;189;248m'  # #b7bdf8
        PEACH='\033[38;2;245;169;127m'     # #f5a97f
        GREEN='\033[38;2;166;218;149m'     # #a6da95
        OVERLAY='\033[38;2;110;115;141m'   # #6e738d
        SUBTEXT='\033[38;2;165;173;203m'   # #a5adcb
        ;;
    mocha)
        BLUE='\033[38;2;137;180;250m'      # #89b4fa
        RED='\033[38;2;243;139;168m'       # #f38ba8
        TEAL='\033[38;2;148;226;213m'      # #94e2d5
        MAUVE='\033[38;2;203;166;247m'     # #cba6f7
        LAVENDER='\033[38;2;180;190;254m'  # #b4befe
        PEACH='\033[38;2;250;179;135m'     # #fab387
        GREEN='\033[38;2;166;227;161m'     # #a6e3a1
        OVERLAY='\033[38;2;108;112;134m'   # #6c7086
        SUBTEXT='\033[38;2;166;173;200m'   # #a6adc8
        ;;
    *) # frappe (default)
        BLUE='\033[38;2;140;170;238m'      # #8caaee
        RED='\033[38;2;231;130;132m'       # #e78284
        TEAL='\033[38;2;129;200;190m'      # #81c8be
        MAUVE='\033[38;2;202;158;230m'     # #ca9ee6
        LAVENDER='\033[38;2;186;187;241m'  # #babbf1
        PEACH='\033[38;2;239;159;118m'     # #ef9f76
        GREEN='\033[38;2;166;209;137m'     # #a6d189
        OVERLAY='\033[38;2;115;121;148m'   # #737994
        SUBTEXT='\033[38;2;165;173;206m'   # #a5adce
        ;;
esac
RESET='\033[0m'

# Format context bar
if [ -z "$used_pct" ] || [ "$used_pct" = "null" ]; then
    context_info="${OVERLAY}░░░░░░░░░░${RESET}"
else
    pct=$(printf "%.0f" "$used_pct" 2>/dev/null || echo "$used_pct")
    [ "$pct" -gt 100 ] 2>/dev/null && pct=100

    # Calculate tokens in k
    used_k=$(( max_ctx * pct / 100 / 1000 ))
    max_k=$(( max_ctx / 1000 ))

    # Build block bar (10 segments)
    filled=$(( pct / 10 ))

    # Blue by default, red when > 60%
    [ "$pct" -gt 60 ] && COLOR="$RED" || COLOR="$BLUE"

    bar=""
    for i in 0 1 2 3 4 5 6 7 8 9; do
        if [ "$i" -lt "$filled" ]; then
            bar="${bar}${COLOR}▓${RESET}"
        else
            bar="${bar}${OVERLAY}░${RESET}"
        fi
    done

    context_info="${bar} ${SUBTEXT}${used_k}k/${max_k}k${RESET}"
fi

# Format cost (convert from USD using exchange rate)
if [ -n "$cost_usd" ] && [ "$cost_usd" != "0" ] && [ "$cost_usd" != "null" ]; then
    rate=$(get_exchange_rate)
    cost_converted=$(echo "$cost_usd * $rate" | bc -l 2>/dev/null || echo "$cost_usd")
    cost_fmt=$(printf "%.2f" "$cost_converted" 2>/dev/null || echo "0.00")
    cost_display="${GREEN}${CURRENCY}${cost_fmt}${RESET}"
else
    cost_display="${OVERLAY}${CURRENCY}0.00${RESET}"
fi

# Build output
output="${LAVENDER}${model}${RESET}"

if [ -n "$branch" ]; then
    output="${output} ${OVERLAY}│${RESET} ${MAUVE}${branch}${RESET}"
    [ -n "$dirty" ] && output="${output}${PEACH}${dirty}${RESET}"
fi

output="${output} ${OVERLAY}│${RESET} ${TEAL}${folder}${RESET}"
output="${output} ${OVERLAY}│${RESET} ${context_info}"
output="${output} ${OVERLAY}│${RESET} ${cost_display}"

# Append version segment
if [ -n "$cc_version" ]; then
    output="${output} ${OVERLAY}│${RESET} ${SUBTEXT}v${cc_version}${RESET}"
fi

printf '%b\n' "$output"
