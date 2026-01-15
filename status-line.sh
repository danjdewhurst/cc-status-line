#!/bin/bash

# Status line - model, git branch, cwd, context usage, cost
# Catppuccin Frappe theme

data=$(cat)

# Single jq call - extract all values at once (tab-separated)
IFS=$'\t' read -r model cwd max_ctx used_pct cost_usd <<< "$(echo "$data" | jq -r '[
    (.model.display_name // .model.id // "unknown"),
    (.workspace.current_dir // ""),
    (.context_window.context_window_size // 200000),
    (.context_window.used_percentage // ""),
    (.cost.total_cost_usd // 0)
] | @tsv')"

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

# Format cost (show cents if < $1, otherwise dollars)
if [ -n "$cost_usd" ] && [ "$cost_usd" != "0" ] && [ "$cost_usd" != "null" ]; then
    # Format to 2 decimal places
    cost_fmt=$(printf "%.2f" "$cost_usd" 2>/dev/null || echo "0.00")
    cost_display="${GREEN}\$${cost_fmt}${RESET}"
else
    cost_display="${OVERLAY}\$0.00${RESET}"
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

printf '%b\n' "$output"
