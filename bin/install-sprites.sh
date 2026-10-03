#!/usr/bin/env bash
# Download animated sprites and build full-frame GIFs for artifact-free Kitty playback.
set -euo pipefail

install_dir="${POKEMON_TERMINAL_HOME:-$HOME/.config/pokemon-terminal}"
fps="${POKEMON_FPS:-8}"
force=0
[[ "${1:-}" == "--force" ]] && force=1

command -v curl >/dev/null || { printf 'curl is required\n' >&2; exit 1; }
command -v magick >/dev/null || { printf 'ImageMagick is required (brew install imagemagick)\n' >&2; exit 1; }

names=(
  gengar pikachu charmander bulbasaur squirtle eevee meowth psyduck
  snorlax jigglypuff growlithe abra cubone machop haunter dragonite
  mew mewtwo chikorita cyndaquil totodile umbreon espeon mudkip
  torchic treecko riolu lucario mimikyu rowlet
)

mkdir -p "$install_dir/sprites" "$install_dir/cache"
download_dir="$(mktemp -d "${TMPDIR:-/tmp}/kitty-pokemon-hud.XXXXXX")"
trap 'rm -rf "$download_dir"' EXIT

scale_for() {
  case "$1" in
    gengar) printf '5' ;;
    pikachu) printf '6' ;;
    charmander) printf '7' ;;
    bulbasaur) printf '8' ;;
    *) printf '6' ;;
  esac
}

for name in "${names[@]}"; do
  sprite_dir="$install_dir/sprites/$name"
  output="$install_dir/cache/$name-${fps}fps-v7-full.gif"
  if [[ "$force" -eq 0 && -s "$output" && -d "$sprite_dir" ]]; then
    printf 'cached  %s\n' "$name"
    continue
  fi

  printf 'building %-12s' "$name"
  source_gif="$download_dir/$name.gif"
  staging_dir="$download_dir/$name-frames"
  mkdir -p "$staging_dir"
  curl --retry 3 --connect-timeout 15 --max-time 120 -fsSL \
    "https://projectpokemon.org/images/normal-sprite/$name.gif" -o "$source_gif"
  magick identify "$source_gif" >/dev/null
  magick "$source_gif" -coalesce +repage "$staging_dir/%03d.png"

  mkdir -p "$sprite_dir"
  find "$sprite_dir" -type f -name '*.png' -delete
  cp "$staging_dir"/*.png "$sprite_dir/"

  scale_factor="$(scale_for "$name")"
  frame_delay=$((100 / fps))
  magick -delay "$frame_delay" -dispose background "$sprite_dir"/*.png \
    -filter point -resize "$((scale_factor * 100))%" -coalesce -loop 0 "$output"
  printf ' %s frames\n' "$(find "$sprite_dir" -type f -name '*.png' | wc -l | tr -d ' ')"
done

printf 'Installed %s animated Pokémon in %s\n' "${#names[@]}" "$install_dir"
