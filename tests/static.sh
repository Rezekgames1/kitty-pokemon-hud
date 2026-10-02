#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n \
  "$repo_dir/install.sh" \
  "$repo_dir/uninstall.sh" \
  "$repo_dir/bin/dashboard.sh" \
  "$repo_dir/bin/pokemon.sh" \
  "$repo_dir/bin/install-sprites.sh" \
  "$repo_dir/bin/doctor.sh"
zsh -n "$repo_dir/shell/pokemon-terminal.zsh"

pokemon_count="$(awk '
  /^  POKEMON_CHOICES=\(/ { inside=1; next }
  inside && /^  \)/ { print count; exit }
  inside { count += NF }
' "$repo_dir/shell/pokemon-terminal.zsh")"
[[ "$pokemon_count" -eq 30 ]] || {
  printf 'Expected 30 Pokémon, found %s\n' "$pokemon_count" >&2
  exit 1
}

test_home="$(mktemp -d "${TMPDIR:-/tmp}/kitty-pokemon-test.XXXXXX")"
trap 'rm -rf "$test_home"' EXIT
printf '# existing zsh config\n' > "$test_home/.zshrc"
mkdir -p "$test_home/.config/kitty"
printf '# existing kitty config\n' > "$test_home/.config/kitty/kitty.conf"

HOME="$test_home" "$repo_dir/install.sh" --skip-deps --skip-assets
HOME="$test_home" "$repo_dir/install.sh" --skip-deps --skip-assets

[[ "$(grep -c '^# >>> kitty-pokemon-hud >>>$' "$test_home/.zshrc")" -eq 1 ]]
[[ "$(grep -c '^# >>> kitty-pokemon-hud >>>$' "$test_home/.config/kitty/kitty.conf")" -eq 1 ]]
[[ -x "$test_home/.config/pokemon-terminal/pokemon.sh" ]]
[[ -x "$test_home/.config/pokemon-terminal/doctor.sh" ]]
[[ -s "$test_home/.config/kitty/pokemon-hud.conf" ]]

HOME="$test_home" "$repo_dir/uninstall.sh"
if grep -q 'kitty-pokemon-hud' "$test_home/.zshrc"; then exit 1; fi
if grep -q 'kitty-pokemon-hud' "$test_home/.config/kitty/kitty.conf"; then exit 1; fi
[[ ! -e "$test_home/.config/pokemon-terminal" ]]

printf 'All static and isolated-install tests passed.\n'
