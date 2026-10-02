#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install_dir="$HOME/.config/pokemon-terminal"
kitty_dir="$HOME/.config/kitty"
kitty_config="$kitty_dir/kitty.conf"
zshrc="$HOME/.zshrc"
skip_deps=0
skip_assets=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [--skip-deps] [--skip-assets]

  --skip-deps    Do not install Homebrew dependencies.
  --skip-assets  Do not download/build the 30 animated Pokémon.
EOF
}

while (($#)); do
  case "$1" in
    --skip-deps) skip_deps=1 ;;
    --skip-assets) skip_assets=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[[ "$(uname -s)" == "Darwin" ]] || {
  printf 'This installer currently supports macOS only.\n' >&2
  exit 1
}

install_formula() {
  local formula="$1"
  brew list --formula "$formula" >/dev/null 2>&1 || brew install "$formula"
}
install_cask() {
  local cask="$1"
  brew list --cask "$cask" >/dev/null 2>&1 || brew install --cask "$cask"
}

if [[ "$skip_deps" -eq 0 ]]; then
  command -v brew >/dev/null || {
    printf 'Homebrew is required: https://brew.sh\n' >&2
    exit 1
  }
  install_formula imagemagick
  install_formula eza
  install_cask kitty
  install_cask font-meslo-lg-nerd-font
fi

for command_name in magick eza kitty curl; do
  command -v "$command_name" >/dev/null || {
    printf 'Missing dependency: %s\n' "$command_name" >&2
    exit 1
  }
done

timestamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="$HOME/.config/kitty-pokemon-hud-backups/$timestamp"
mkdir -p "$backup_dir" "$install_dir" "$kitty_dir"
[[ -f "$zshrc" ]] && cp "$zshrc" "$backup_dir/zshrc"
[[ -f "$kitty_config" ]] && cp "$kitty_config" "$backup_dir/kitty.conf"

install -m 0755 "$repo_dir/bin/pokemon.sh" "$install_dir/pokemon.sh"
install -m 0755 "$repo_dir/bin/dashboard.sh" "$install_dir/dashboard.sh"
install -m 0755 "$repo_dir/bin/install-sprites.sh" "$install_dir/install-sprites.sh"
install -m 0755 "$repo_dir/bin/doctor.sh" "$install_dir/doctor.sh"
install -m 0644 "$repo_dir/config/dashboard.conf" "$install_dir/config"
install -m 0644 "$repo_dir/shell/pokemon-terminal.zsh" "$install_dir/pokemon-terminal.zsh"
install -m 0644 "$repo_dir/config/kitty-pokemon-hud.conf" "$kitty_dir/pokemon-hud.conf"

if [[ "$skip_assets" -eq 0 ]]; then
  POKEMON_TERMINAL_HOME="$install_dir" "$install_dir/install-sprites.sh"
fi

replace_managed_block() {
  local file="$1" start="$2" end="$3" body="$4" temp
  touch "$file"
  temp="$(mktemp "${TMPDIR:-/tmp}/kitty-pokemon-config.XXXXXX")"
  awk -v start="$start" -v end="$end" '
    $0 == start { skipping=1; next }
    $0 == end { skipping=0; next }
    !skipping { print }
  ' "$file" > "$temp"
  mv "$temp" "$file"
  printf '\n%s\n%s\n%s\n' "$start" "$body" "$end" >> "$file"
}

replace_managed_block "$kitty_config" \
  '# >>> kitty-pokemon-hud >>>' '# <<< kitty-pokemon-hud <<<' \
  'include pokemon-hud.conf'
# HOME must expand later, when Zsh reads the installed line.
# shellcheck disable=SC2016
replace_managed_block "$zshrc" \
  '# >>> kitty-pokemon-hud >>>' '# <<< kitty-pokemon-hud <<<' \
  '[[ -r "$HOME/.config/pokemon-terminal/pokemon-terminal.zsh" ]] && source "$HOME/.config/pokemon-terminal/pokemon-terminal.zsh"'

printf '\nKitty Pokémon HUD installed.\n'
printf 'Backup: %s\n' "$backup_dir"
printf 'Open a new Kitty window or run: exec zsh\n'
