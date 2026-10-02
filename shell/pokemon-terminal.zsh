# Kitty Pokémon HUD shell integration. Sourced from ~/.zshrc by install.sh.
if [[ "${TERM:-}" == "xterm-kitty" && -n "${KITTY_WINDOW_ID:-}" && -z "${SSH_CONNECTION:-}${SSH_TTY:-}" && -o interactive ]]; then
  export POKEMON_TERMINAL_HOME="${POKEMON_TERMINAL_HOME:-$HOME/.config/pokemon-terminal}"
  export EZA_COLORS='di=1;34:ex=1;32:*.py=1;33:*.sh=1;32:*.zip=1;31:*.tar=1;31:*.gz=1;31:*.txt=0;37:*.md=1;35:*.conf=1;36:*.json=1;33:*.yaml=1;33:*.yml=1;33:*.php=1;35'

  if (( $+commands[eza] )); then
    alias ls='eza --color=always --icons=always --classify=always --group-directories-first'
    alias ll='eza -lah --color=always --icons=always --classify=always --group-directories-first --color-scale=age,size'
    alias la='eza -a --color=always --icons=always --classify=always --group-directories-first'
  else
    export CLICOLOR=1
    alias ls='ls -G'
    alias ll='ls -lahG'
    alias la='ls -aG'
  fi

  autoload -Uz colors vcs_info add-zsh-hook
  colors
  setopt prompt_subst
  zstyle ':vcs_info:git:*' formats ' %F{magenta}git:%b%f'
  add-zsh-hook precmd vcs_info
  PROMPT='%F{cyan}╭─%F{blue}%n%F{yellow}⚡%F{blue}%m%f %F{green}%~%f${vcs_info_msg_0_}
%F{cyan}╰─%F{magenta}❯%f '
  RPROMPT='%F{cyan}%*%f'

  POKEMON_CHOICES=(
    gengar pikachu charmander bulbasaur squirtle eevee meowth psyduck
    snorlax jigglypuff growlithe abra cubone machop haunter dragonite
    mew mewtwo chikorita cyndaquil totodile umbreon espeon mudkip
    torchic treecko riolu lucario mimikyu rowlet
  )
  POKEMON_CURRENT="${POKEMON_CURRENT:-gengar}"

  pokemon-start() {
    POKEMON_CURRENT="${1:-$POKEMON_CURRENT}"
    "$POKEMON_TERMINAL_HOME/pokemon.sh" start "$POKEMON_CURRENT"
  }
  pokemon-stop() { "$POKEMON_TERMINAL_HOME/pokemon.sh" stop; }
  pokemon-list() { printf '%s\n' "${POKEMON_CHOICES[@]}"; }
  pokemon-pick-random() {
    local state_file="$POKEMON_TERMINAL_HOME/last-pokemon"
    local previous='' candidate
    local -a candidates
    [[ -r "$state_file" ]] && previous="$(<"$state_file")"
    candidates=()
    for candidate in "${POKEMON_CHOICES[@]}"; do
      [[ "$candidate" != "$previous" ]] && candidates+=("$candidate")
    done
    POKEMON_CURRENT="${candidates[$((RANDOM % ${#candidates[@]} + 1))]}"
    printf '%s\n' "$POKEMON_CURRENT" >| "$state_file"
  }
  pokemon-random() {
    pokemon-pick-random
    pokemon-start "$POKEMON_CURRENT"
  }
  pokemon() { pokemon-start "${1:-gengar}"; }
  pokemon-dashboard() { "$POKEMON_TERMINAL_HOME/dashboard.sh" "${1:-$POKEMON_CURRENT}"; }

  # Kitty clears graphics placements with terminal text, so redraw the HUD.
  clear() { pokemon-dashboard "$POKEMON_CURRENT"; }
  pokemon-clear-screen() {
    clear
    zle reset-prompt
  }
  zle -N pokemon-clear-screen
  bindkey '^L' pokemon-clear-screen

  pokemon-pick-random
  pokemon-dashboard "$POKEMON_CURRENT"
fi
