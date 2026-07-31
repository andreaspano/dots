# =========================
# ~/.bashrc (clean, robust)
# =========================
# This is the ONLY config file with real content.
# ~/.bash_profile is a 2-line shim that sources this file for login shells.
# There is deliberately no ~/.profile (bash ignores it once ~/.bash_profile
# exists); a backup of the old one is at ~/.profile.bak.

# If not running interactively, do nothing.
# REQUIRED: sshd sources ~/.bashrc for non-interactive remote commands, and any
# byte printed here (e.g. .title below) corrupts scp / sftp / rsync transfers.
case $- in
    *i*) ;;
      *) return;;
esac

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
# History
# =========================
shopt -s histappend      # append instead of overwriting (multiple terminals)
shopt -s checkwinsize
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth   # skip duplicates and lines starting with a space
HISTTIMEFORMAT='%F %T '

# =========================
# Completion
# =========================
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

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

# Used by `alias a` in ~/.bash_aliases: activate the nearest .venv,
# searching the current directory and then upwards.
activate_venv() {
  local dir="$PWD"
  while [ -n "$dir" ]; do
    if [ -f "$dir/.venv/bin/activate" ]; then
      . "$dir/.venv/bin/activate"
      return 0
    fi
    [ "$dir" = "/" ] && break
    dir="$(dirname "$dir")"
  done
  echo "activate_venv: no .venv found in $PWD or any parent" >&2
  return 1
}

.prompt() {
  # MUST be first
  local EXIT="$?"

  # PS1-safe colors
  local Red='\[\e[0;31m\]'
  local Blu='\[\e[0;34m\]'
  local Grn='\[\e[0;92m\]'
  local Reset='\[\e[0m\]'

  local last git venv
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
# append (lowest priority)
.path_add() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) : ;;
    *) PATH="$PATH:$1" ;;
  esac
}

# prepend (overrides system binaries) -- used for the private bin dirs that
# ~/.profile used to handle, including the one uv's ~/.local/bin/env set up
.path_prepend() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) : ;;
    *) PATH="$1:$PATH" ;;
  esac
}

.path_prepend "$HOME/bin"
.path_prepend "$HOME/.local/bin"
.path_add "$HOME/gdrive/personal/bin"
.path_add /opt/nvim-linux-x86_64/bin

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

# HOSTALIASES only works if the file exists; an unreadable path makes some
# resolvers noisy, so set it conditionally.
[ -f "$HOME/.hosts" ] && export HOSTALIASES="$HOME/.hosts"

# =========================
# keys
# =========================
# Source every key file found in the keys dir (which lives on adrive, so it is
# simply absent on machines where that drive is not mounted).
# Check with:  keys_status
KEYS_DIR="$HOME/adrive/keys"
if [ -d "$KEYS_DIR" ]; then
  for f in "$KEYS_DIR"/*_key; do
    [ -f "$f" ] && source "$f"
  done
fi
unset f

keys_status() {
  local k
  for k in OPENAI_API_KEY GEMINI_API_KEY DEEPSEEK_API_KEY ANTHROPIC_API_KEY; do
    if [ -n "${!k}" ]; then
      printf '  %-20s set\n' "$k"
    else
      printf '  %-20s MISSING\n' "$k"
    fi
  done
  [ -d "$KEYS_DIR" ] || printf '  (keys dir %s does not exist)\n' "$KEYS_DIR"
}

export OLLAMA_API_BASE=http://mutolo:11434


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
