#!/bin/bash

# Status line - model, git branch, cwd, context usage, cost
# Catppuccin Frappe theme

# Configuration
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

# Read effort level from Claude Code settings (project-level overrides global)
effort=""
project_dir=$(echo "$data" | jq -r '.workspace.project_dir // empty' 2>/dev/null)
if [ -n "$project_dir" ]; then
    # Project settings path uses the dir path with / replaced by -
    project_slug=$(echo "$project_dir" | sed 's|/|-|g')
    effort=$(jq -r '.effortLevel // empty' "${HOME}/.claude/projects/${project_slug}/settings.json" 2>/dev/null)
fi
[ -z "$effort" ] && effort=$(jq -r '.effortLevel // empty' "${HOME}/.claude/settings.json" 2>/dev/null)

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

# Catppuccin Frappe colors (24-bit true color)
BLUE='\033[38;2;140;170;238m'      # Blue - context bar (low)
RED='\033[38;2;231;130;132m'       # Red - context bar (high)
TEAL='\033[38;2;129;200;190m'      # Teal - folder
MAUVE='\033[38;2;202;158;230m'     # Mauve - git branch
LAVENDER='\033[38;2;186;187;241m'  # Lavender - model
PEACH='\033[38;2;239;159;118m'     # Peach - dirty indicator
GREEN='\033[38;2;166;209;137m'     # Green - cost
OVERLAY='\033[38;2;115;121;148m'   # Overlay 0 - separators
SUBTEXT='\033[38;2;165;173;206m'   # Subtext 0 - secondary text
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

# Format effort indicator
effort_display=""
if [ -n "$effort" ] && [ "$effort" != "null" ]; then
    case "$effort" in
        low)    effort_display=" ${SUBTEXT}Low${RESET}" ;;
        medium) effort_display=" ${SUBTEXT}Med${RESET}" ;;
        *)      effort_display="" ;;  # hide default (high)
    esac
fi

# Build output
output="${LAVENDER}${model}${RESET}${effort_display}"

if [ -n "$branch" ]; then
    output="${output} ${OVERLAY}│${RESET} ${MAUVE}${branch}${RESET}"
    [ -n "$dirty" ] && output="${output}${PEACH}${dirty}${RESET}"
fi

output="${output} ${OVERLAY}│${RESET} ${TEAL}${folder}${RESET}"
output="${output} ${OVERLAY}│${RESET} ${context_info}"
output="${output} ${OVERLAY}│${RESET} ${cost_display}"

printf '%b\n' "$output"
