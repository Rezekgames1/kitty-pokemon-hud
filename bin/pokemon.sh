#!/usr/bin/env bash
# Place a cached animated Pokémon through Kitty's native graphics protocol.
set -euo pipefail

base_dir="${POKEMON_TERMINAL_HOME:-$HOME/.config/pokemon-terminal}"
config_file="$base_dir/config"
# The installed runtime config path is intentionally dynamic.
# shellcheck disable=SC1090
[[ -r "$config_file" ]] && source "$config_file"

POKEMON_NAME="${POKEMON_NAME:-gengar}"
POKEMON_FPS="${POKEMON_FPS:-6}"
POKEMON_WIDTH="${POKEMON_WIDTH:-20}"
POKEMON_HEIGHT="${POKEMON_HEIGHT:-10}"
POKEMON_LEFT="${POKEMON_LEFT:-1}"
POKEMON_TOP="${POKEMON_TOP:-1}"
IMAGE_ID=424242

POKEMON_CHOICES=(
  gengar pikachu charmander bulbasaur squirtle eevee meowth psyduck
  snorlax jigglypuff growlithe abra cubone machop haunter dragonite
  mew mewtwo chikorita cyndaquil totodile umbreon espeon mudkip
  torchic treecko riolu lucario mimikyu rowlet
)

usage() {
  printf 'Usage: pokemon.sh {start POKEMON|stop|random}\n' >&2
}

require_kitty() {
  [[ "${TERM:-}" == xterm-kitty && -n "${KITTY_WINDOW_ID:-}" ]] || {
    printf 'Pokémon overlay is available only inside Kitty.\n' >&2
    exit 1
  }
  [[ -z "${SSH_CONNECTION:-}${SSH_TTY:-}" ]] || exit 0
}

stop_overlay() {
  # The final backslash terminates Kitty's APC.
  # shellcheck disable=SC1003
  printf '\033_Ga=d,d=I,i=%s,q=2\033\\' "$IMAGE_ID" > /dev/tty
}

create_animation() {
  local name="$1" sprite_dir cache_dir output scale_factor frame_delay
  sprite_dir="$base_dir/sprites/$name"
  cache_dir="$base_dir/cache"
  case "$name" in
    gengar) scale_factor=5 ;;
    pikachu) scale_factor=6 ;;
    charmander) scale_factor=7 ;;
    bulbasaur) scale_factor=8 ;;
    *) scale_factor=6 ;;
  esac
  output="$cache_dir/$name-${POKEMON_FPS}fps-v7-full.gif"

  [[ -d "$sprite_dir" ]] || {
    printf 'Unknown or uninstalled Pokémon: %s\n' "$name" >&2
    exit 2
  }
  mkdir -p "$cache_dir"
  if [[ ! -s "$output" ]]; then
    frame_delay=$((100 / POKEMON_FPS))
    magick -delay "$frame_delay" -dispose background "$sprite_dir"/*.png \
      -filter point -resize "$((scale_factor * 100))%" -coalesce -loop 0 "$output"
  fi
  printf '%s\n' "$output"
}

start_overlay() {
  local name="${1:-$POKEMON_NAME}" animation
  require_kitty
  animation="$(create_animation "$name")"
  stop_overlay
  printf '\0337' > /dev/tty
  kitty +kitten icat --stdin=no --transfer-mode=file \
    --place "${POKEMON_WIDTH}x${POKEMON_HEIGHT}@${POKEMON_LEFT}x${POKEMON_TOP}" \
    --align center --scale-up=no --loop -1 --image-id "$IMAGE_ID" \
    --no-trailing-newline "$animation" > /dev/tty
  printf '\0338' > /dev/tty
}

case "${1:-start}" in
  start) start_overlay "${2:-$POKEMON_NAME}" ;;
  stop) require_kitty; stop_overlay ;;
  random) start_overlay "${POKEMON_CHOICES[RANDOM % ${#POKEMON_CHOICES[@]}]}" ;;
  *) usage; exit 2 ;;
esac
