<p align="center">
  <h1 align="center">Claude Code Status Line</h1>
  <p align="center">
    A <a href="https://catppuccin.com/">Catppuccin Frappe</a>-themed status line for <a href="https://github.com/anthropics/claude-code">Claude Code</a>
  </p>
</p>

<p align="center">
  <a href="#install"><img src="https://img.shields.io/badge/install-one--liner-blue?style=flat-square" alt="Install"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License"></a>
</p>

```
Opus 4.6 │ feat/my-branch● │ my-project │ ▓▓▓░░░░░░░ 15k/200k │ $0.03 │ v2.1.52
```

**Model** · **Git branch** (with dirty indicator) · **Project folder** · **Context usage** (visual bar + tokens) · **Session cost** (auto-converting currency) · **CLI version**

---

## Install

```bash
mkdir -p ~/.claude/scripts && \
  curl -fsSL https://raw.githubusercontent.com/danjdewhurst/cc-status-line/main/status-line.sh \
  -o ~/.claude/scripts/status-line.sh && \
  chmod +x ~/.claude/scripts/status-line.sh
```

<details>
<summary>Or with wget</summary>

```bash
mkdir -p ~/.claude/scripts && \
  wget -qO ~/.claude/scripts/status-line.sh \
  https://raw.githubusercontent.com/danjdewhurst/cc-status-line/main/status-line.sh && \
  chmod +x ~/.claude/scripts/status-line.sh
```
</details>

Then add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/scripts/status-line.sh"
  }
}
```

Restart Claude Code or start a new session.

## Requirements

- Terminal with 24-bit true colour support (iTerm2, Ghostty, Kitty, WezTerm, Alacritty)
- [`jq`](https://jqlang.github.io/jq/) and `bc`
- `curl` (optional — for exchange rate API, falls back to manual rate)
- `git` (optional — for branch display)

## Customisation

<details>
<summary><strong>Change currency</strong></summary>

Exchange rates are fetched from the [Frankfurter API](https://www.frankfurter.app/) and cached for 24 hours at `~/.cache/cc-status-line/exchange-rate.json`.

Edit the variables at the top of the script:

```bash
CURRENCY='£'
CURRENCY_CODE='GBP'
EXCHANGE_RATE=0.79    # Fallback if API unavailable
```

Supports any [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code (`EUR`, `JPY`, `AUD`, etc.).
</details>

<details>
<summary><strong>Change context bar threshold</strong></summary>

The bar turns red when usage exceeds 60%. Adjust in the script:

```bash
[ "$pct" -gt 60 ] && COLOR="$RED" || COLOR="$BLUE"
```
</details>

<details>
<summary><strong>Change bar characters</strong></summary>

Replace `▓` and `░` with alternatives:

| Style | Filled | Empty |
|-------|--------|-------|
| Default | `▓` | `░` |
| Circles | `●` | `○` |
| Blocks | `█` | `░` |
| Thin | `┃` | `│` |
</details>

<details>
<summary><strong>Change branch truncation</strong></summary>

Branch names are truncated at 20 characters. Adjust in the script:

```bash
if [ "${#branch}" -gt 20 ]; then
    branch="${branch:0:19}…"
fi
```
</details>

## Colour Palette

All colours are from [Catppuccin Frappe](https://github.com/catppuccin/catppuccin):

| Element | Colour | RGB |
|---------|--------|-----|
| Model | Lavender | `186, 187, 241` |
| Branch | Mauve | `202, 158, 230` |
| Folder | Teal | `129, 200, 190` |
| Context (low) | Blue | `140, 170, 238` |
| Context (high) | Red | `231, 130, 132` |
| Dirty indicator | Peach | `239, 159, 118` |
| Cost | Green | `166, 209, 137` |
| Separators | Overlay 0 | `115, 121, 148` |
| Version / secondary | Subtext 0 | `165, 173, 206` |

## Testing

```bash
echo '{"model":{"display_name":"Opus 4.6"},"workspace":{"current_dir":"/Users/you/project"},"context_window":{"context_window_size":200000,"used_percentage":25},"cost":{"total_cost_usd":0.05}}' | ./status-line.sh
```

## Licence

[MIT](LICENSE)
