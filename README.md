# Claude Code Status Line

A custom status line for [Claude Code](https://github.com/anthropics/claude-code) featuring the [Catppuccin Frappe](https://catppuccin.com/) color palette.

```
Opus 4.5 │ feat/my-branch● │ my-project │ ▓▓▓░░░░░░░ 15k/200k │ £0.02
```

## Features

- **Model name** - Current Claude model in use
- **Git branch** - Current branch with dirty indicator (●) when uncommitted changes exist
- **Project folder** - Current working directory name
- **Context usage** - Visual bar + token count (blue < 60%, red > 60%)
- **Session cost** - Running total with configurable currency and exchange rate

## Requirements

- Terminal with 24-bit true color support (iTerm2, Ghostty, Kitty, WezTerm, Alacritty)
- `jq` for JSON parsing
- `bc` for currency conversion
- `git` (optional, for branch display)

## Quick Install

```bash
mkdir -p ~/.claude/scripts && curl -fsSL https://raw.githubusercontent.com/danjdewhurst/cc-status-line/main/status-line.sh -o ~/.claude/scripts/status-line.sh && chmod +x ~/.claude/scripts/status-line.sh
```

Or with wget:

```bash
mkdir -p ~/.claude/scripts && wget -qO ~/.claude/scripts/status-line.sh https://raw.githubusercontent.com/danjdewhurst/cc-status-line/main/status-line.sh && chmod +x ~/.claude/scripts/status-line.sh
```

Then add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/scripts/status-line.sh"
  }
}
```

## Manual Installation

1. Copy the script to your Claude scripts directory:

```bash
mkdir -p ~/.claude/scripts
cp status-line.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/status-line.sh
```

2. Configure Claude Code to use it. Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/scripts/status-line.sh"
  }
}
```

3. Restart Claude Code or start a new session.

## Catppuccin Frappe Colors

| Element | Color | RGB |
|---------|-------|-----|
| Model | Lavender | `(186, 187, 241)` |
| Branch | Mauve | `(202, 158, 230)` |
| Folder | Teal | `(129, 200, 190)` |
| Context (low) | Blue | `(140, 170, 238)` |
| Context (high) | Red | `(231, 130, 132)` |
| Dirty indicator | Peach | `(239, 159, 118)` |
| Cost | Green | `(166, 209, 137)` |
| Separators | Overlay 0 | `(115, 121, 148)` |
| Secondary text | Subtext 0 | `(165, 173, 206)` |

## Customization

### Change currency

Edit the currency symbol and exchange rate (default GBP):

```bash
CURRENCY='£'              # Currency symbol
EXCHANGE_RATE=0.79        # USD to GBP
```

Other examples:

```bash
# US Dollars (no conversion)
CURRENCY='$'
EXCHANGE_RATE=1

# Euros
CURRENCY='€'
EXCHANGE_RATE=0.92

# Japanese Yen
CURRENCY='¥'
EXCHANGE_RATE=149.50
```

### Change color threshold

Edit the threshold for when the context bar turns red (default 60%):

```bash
[ "$pct" -gt 60 ] && COLOR="$RED" || COLOR="$BLUE"
```

### Change branch truncation length

Edit the max length (default 20 characters):

```bash
if [ "${#branch}" -gt 20 ]; then
    branch="${branch:0:19}…"
fi
```

### Use different bar characters

Replace `▓` and `░` with alternatives:

- Circles: `●` and `○`
- Blocks: `█` and `░`
- Thin: `┃` and `│`

## Testing

Test the script manually:

```bash
echo '{"model":{"display_name":"Opus 4.5"},"workspace":{"current_dir":"/Users/you/project"},"context_window":{"context_window_size":200000,"used_percentage":25},"cost":{"total_cost_usd":0.05}}' | ./status-line.sh
```

## License

MIT
