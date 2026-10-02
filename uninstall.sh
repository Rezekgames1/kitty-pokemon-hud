#!/usr/bin/env bash
set -euo pipefail

install_dir="$HOME/.config/pokemon-terminal"
kitty_theme="$HOME/.config/kitty/pokemon-hud.conf"

remove_managed_block() {
  local file="$1" start="$2" end="$3" temp
  [[ -f "$file" ]] || return 0
  temp="$(mktemp "${TMPDIR:-/tmp}/kitty-pokemon-config.XXXXXX")"
  awk -v start="$start" -v end="$end" '
    $0 == start { skipping=1; next }
    $0 == end { skipping=0; next }
    !skipping { print }
  ' "$file" > "$temp"
  mv "$temp" "$file"
}

remove_managed_block "$HOME/.config/kitty/kitty.conf" \
  '# >>> kitty-pokemon-hud >>>' '# <<< kitty-pokemon-hud <<<'
remove_managed_block "$HOME/.zshrc" \
  '# >>> kitty-pokemon-hud >>>' '# <<< kitty-pokemon-hud <<<'

[[ "$kitty_theme" == "$HOME/.config/kitty/pokemon-hud.conf" ]] && rm -f "$kitty_theme"
[[ "$install_dir" == "$HOME/.config/pokemon-terminal" ]] && rm -rf "$install_dir"

printf 'Kitty Pokémon HUD removed. Homebrew dependencies were kept.\n'
printf 'Backups, if any: %s\n' "$HOME/.config/kitty-pokemon-hud-backups"
