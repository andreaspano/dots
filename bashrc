# =========================
# ~/.bashrc (clean, robust)
# =========================

# ----- Prompt hook -----
PROMPT_COMMAND=.prompt

# =========================
# functions
# =========================
for f in ~/dev/dots/fun*.sh; do
    [ -f "$f" ] && source "$f"
done


# =========================
# Terminal title (GNOME Terminal / xterm compatible)
# =========================
.title() {
  # title: user@host
  printf '\033]0;%s@%s\007' "$USER" "${HOSTNAME:-$(hostname -s 2>/dev/null)}"
}
.title

# =========================
# GNOME Terminal: read profile colors for exact restore
# =========================
.gt_profile_uuid() {
  # default profile UUID
  gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'"
}

.gt_init_profile_colors() {
  local uuid schema
  uuid="$(.gt_profile_uuid)"
  [ -n "$uuid" ] || return 0

  schema="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${uuid}/"

  # gsettings returns strings like: rgb(255,255,255) OR 'rgb(255,255,255)' depending on version
  _GT_FG="$(gsettings get "$schema" foreground-color 2>/dev/null | tr -d "'")"
  _GT_CURSOR="$(gsettings get "$schema" cursor-background-color 2>/dev/null | tr -d "'")"

  # safe fallbacks
  [ -n "$_GT_FG" ] || _GT_FG="rgb(255,255,255)"
  [ -n "$_GT_CURSOR" ] || _GT_CURSOR="rgb(255,255,255)"
}

if command -v gsettings >/dev/null 2>&1; then
  .gt_init_profile_colors
fi

# =========================
# SSH wrapper: change ONLY foreground & cursor, restore exactly
# =========================
# --- ripristino colori esatti del profilo GNOME Terminal ---
# Colore "REMOTE" (solo testo) usando ANSI standard
.ssh_colors_on() {
  printf '\e[38;5;48m'   # testo verde-acqua (256 colors)
  # oppure semplice verde: printf '\e[0;32m'
}

.ssh_colors_off() {
  # reset standard del testo al default del profilo
  printf '\e[0m\e[39m'
}

ssh() {
  # Pass through if any options or remote command are given
  local has_option=0
  for arg in "$@"; do
    case "$arg" in
      -*) has_option=1; break ;;
    esac
  done
  if (( has_option || $# > 1 )); then
    command /usr/bin/ssh "$@"
    return $?
  fi

  local host="$1"

  # Prompt remoto: andrea@mutolo> (verde), senza :~$
  command /usr/bin/ssh -t "$host" \
    "env PS1='\[\e[38;5;34m\]\u@\h>\[\e[0m\] ' bash --noprofile --norc -i"
}


# =========================
# su wrapper: restore title after exit
# =========================
su() {
  /bin/su "$@"
  .title
}

# =========================
# Prompt helpers
# =========================
.last_command() {
  local code="${1:-0}"
  local Red='\[\e[0;31m\]'
  local Gre='\[\e[0;32m\]'
  local Reset='\[\e[0m\]'

  if (( code != 0 )); then
    printf '%b' "${Red}✗ ${Reset}"
  else
    printf '%b' "${Gre}✓ ${Reset}"
  fi
}

.git_info() {
  # fast check
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

  local branch
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" || branch="detached"

  printf '[%s] ' "$branch"
}



#=========================
# Prompt
#=========================

# Fallback: defined here if not provided by fun*.sh
if ! declare -f venv_info >/dev/null 2>&1; then
  venv_info() {
    [ -n "$VIRTUAL_ENV" ] && printf '(%s) ' "$(basename "$VIRTUAL_ENV")"
  }
fi

.prompt() {
  # MUST be first
  local EXIT="$?"

  # PS1-safe colors
  local Red='\[\e[0;31m\]'
  local Blu='\[\e[0;34m\]'
  local Grn='\[\e[0;92m\]'
  local Reset='\[\e[0m\]'

  local last git
  last="$(.last_command "$EXIT")"
  git="$(.git_info)"
  venv="$(venv_info)"

  # Different prompt when connected via SSH
  if [[ -n "$SSH_CONNECTION" ]]; then
    PS1='\[\e[1;31m\][MUTOLO]\[\e[0m\] \u@\h:\w\$ '
    return
  fi

  # End with Reset so input starts clean
  PS1="${Red}\w ${Blu}${git}${Grn}${venv}${Reset}\n${last}"
}

# =========================
# Git identity (only if git exists)
# =========================
if command -v git >/dev/null 2>&1; then
  [ "$(git config --global user.email)" = "andrea@spano.it" ] || git config --global user.email "andrea@spano.it"
  [ "$(git config --global user.name)" = "andreaspano" ] || git config --global user.name "andreaspano"
fi

# =========================
# Env vars
# =========================
export VISUAL=vim
export EDITOR=vim

# Avoid GTK warnings when using ssh -X
export NO_AT_BRIDGE=1

# =========================
# PATH management (avoid duplicates)
# =========================
.path_add() {
  case ":$PATH:" in
    *":$1:"*) : ;;
    *) PATH="$PATH:$1" ;;
  esac
}

.path_add "$HOME/.local/bin"
.path_add "$HOME/gdrive/personal/bin"

# CUDA (only if present)
if [ -d /usr/local/cuda/bin ]; then
  PATH="/usr/local/cuda/bin:$PATH"
fi
if [ -d /usr/local/cuda/lib64 ]; then
  export LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH:-}"
fi
export PATH

# =========================
# Includes
# =========================
if [ -f "$HOME/.bash_aliases" ]; then
  . "$HOME/.bash_aliases"
fi

export HOSTALIASES="$HOME/.hosts"

# =========================
# keys
# =========================
[ -f ~/adrive/keys/openai_key ]    && source ~/adrive/keys/openai_key
[ -f ~/adrive/keys/gemini_key ]    && source ~/adrive/keys/gemini_key
[ -f ~/adrive/keys/deepseek_key ]  && source ~/adrive/keys/deepseek_key
#[ -f ~/adrive/keys/anthropic_key ] && source ~/adrive/keys/anthropic_key

# noevim
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"


export OLLAMA_API_BASE=http://mutolo:11434


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
