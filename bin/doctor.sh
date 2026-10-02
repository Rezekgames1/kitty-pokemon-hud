#!/usr/bin/env bash
set -euo pipefail

install_dir="${POKEMON_TERMINAL_HOME:-$HOME/.config/pokemon-terminal}"
failed=0

check_command() {
  if command -v "$1" >/dev/null; then
    printf 'ok   command: %s\n' "$1"
  else
    printf 'FAIL command: %s\n' "$1"
    failed=1
  fi
}

for command_name in kitty magick eza curl zsh; do check_command "$command_name"; done

for file in "$install_dir/config" "$install_dir/pokemon.sh" "$install_dir/dashboard.sh" "$install_dir/pokemon-terminal.zsh"; do
  if [[ -s "$file" ]]; then
    printf 'ok   file: %s\n' "$file"
  else
    printf 'FAIL file: %s\n' "$file"
    failed=1
  fi
done

sprite_count="$(find "$install_dir/sprites" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
cache_count="$(find "$install_dir/cache" -type f -name '*-full.gif' 2>/dev/null | wc -l | tr -d ' ')"
printf '%s sprites: %s/30\n' "$([[ "$sprite_count" -eq 30 ]] && printf ok || printf FAIL)" "$sprite_count"
printf '%s caches:  %s/30\n' "$([[ "$cache_count" -eq 30 ]] && printf ok || printf FAIL)" "$cache_count"
[[ "$sprite_count" -eq 30 && "$cache_count" -eq 30 ]] || failed=1

bash -n "$install_dir/dashboard.sh" "$install_dir/pokemon.sh"
zsh -n "$install_dir/pokemon-terminal.zsh"
printf 'ok   shell syntax\n'

exit "$failed"
