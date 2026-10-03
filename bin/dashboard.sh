#!/usr/bin/env bash
# Draw an animated Pokémon and a compact system/network HUD in Kitty.
set -euo pipefail

base_dir="${POKEMON_TERMINAL_HOME:-$HOME/.config/pokemon-terminal}"
# The installed runtime config path is intentionally dynamic.
# shellcheck disable=SC1091
source "$base_dir/config"
name="${1:-${POKEMON_NAME:-gengar}}"

printf '\033[2J\033[H' > /dev/tty
"$base_dir/pokemon.sh" start "$name"

cyan=$'\033[38;5;51m'
blue=$'\033[38;5;117m'
lavender=$'\033[38;5;183m'
green=$'\033[38;5;114m'
red=$'\033[38;5;203m'
reset=$'\033[0m'

os_version="$(sw_vers -productVersion)"
host="$(sysctl -n hw.model | sed 's/,.*//')"
cpu="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'Apple Silicon')"
memory_gib="$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 )) GiB"
memory_free_pct="$(memory_pressure -Q 2>/dev/null | awk '/free percentage:/{gsub(/%/, "", $NF); print $NF; exit}')"
[[ "$memory_free_pct" =~ ^[0-9]+$ ]] || memory_free_pct=0
memory_used_pct=$((100 - memory_free_pct))
memory_bar=""
for ((i = 1; i <= 10; i++)); do
  if ((i * 10 <= memory_used_pct)); then memory_bar+="█"; else memory_bar+="░"; fi
done

uptime_text="$(uptime | sed -E 's/^.*up +//; s/, +[0-9]+ users?.*$//')"
kitty_version="$(kitty --version | awk '{print $2}')"
if [[ "${POKEMON_HUD_DEMO:-0}" == "1" ]]; then
  lan_iface="en0"
  lan_ip="192.168.1.42"
  vpn_iface="utun4"
  vpn_ip="10.8.0.2"
else
  lan_iface="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"
  lan_ip="$(ipconfig getifaddr "$lan_iface" 2>/dev/null || true)"
  [[ -n "$lan_ip" ]] || lan_ip="offline"

  vpn_iface=""
  vpn_ip=""
  for iface in $(ifconfig -l | tr ' ' '\n' | awk '/^utun[0-9]+$/'); do
    address="$(ifconfig "$iface" 2>/dev/null | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}')"
    if [[ -n "$address" ]]; then
      vpn_iface="$iface"
      vpn_ip="$address"
      break
    fi
  done
  [[ -n "$vpn_ip" ]] || vpn_ip="offline"
fi

card_inner_width=41
repeat_rule() {
  local count="$1" result
  printf -v result '%*s' "$count" ''
  printf '%s' "${result// /─}"
}
card_rule() {
  local left="$1" title="$2" right="$3" fill
  fill="$(repeat_rule "$((card_inner_width - ${#title}))")"
  printf '%s%s%s%s%s%s' "$cyan" "$left" "$title" "$fill" "$right" "$reset"
}
card_row() {
  local label="$1" value="$2" value_color="${3:-$blue}" line padding padding_width
  padding_width=$((31 - ${#value}))
  ((padding_width < 0)) && padding_width=0
  printf -v padding '%*s' "$padding_width" ''
  printf -v line '%s│%s %s%-8s%s %s%s%s%s%s│%s' \
    "$cyan" "$reset" "$cyan" "$label" "$reset" "$value_color" "$value" \
    "$reset" "$padding" "$cyan" "$reset"
  printf '%s' "$line"
}

lan_status_color="$green"
vpn_status_color="$green"
[[ "$lan_ip" == "offline" ]] && lan_status_color="$red"
[[ "$vpn_ip" == "offline" ]] && vpn_status_color="$red"

info_lines=(
  "$(card_rule '╭' '─ ◆ SYSTEM ' '╮')"
  "$(card_row 'OS' "macOS ${os_version}")"
  "$(card_row 'HOST' "${host} · Darwin $(uname -r)")"
  "$(card_row 'UPTIME' "$uptime_text")"
  "$(card_row 'SHELL' "zsh 5.9 · Kitty ${kitty_version}")"
  "$(card_row 'CPU' "$cpu")"
  "$(card_row 'RAM' "${memory_bar} ${memory_used_pct}% · ${memory_gib}" "$lavender")"
  "$(card_rule '├' '─ ◆ NETWORK ' '┤')"
  "$(card_row 'LAN' "● ${lan_ip}${lan_iface:+ · ${lan_iface}}" "$lan_status_color")"
  "$(card_row 'VPN' "● ${vpn_ip}${vpn_iface:+ · ${vpn_iface}}" "$vpn_status_color")"
  "$(card_rule '╰' '' '╯')"
)

for ((i = 0; i < ${#info_lines[@]}; i++)); do
  printf '\033[%d;%dH%s' "$((DASHBOARD_INFO_TOP + i))" "$DASHBOARD_INFO_LEFT" "${info_lines[$i]}" > /dev/tty
done

printf '\033[%d;1H' "$DASHBOARD_PROMPT_TOP" > /dev/tty
