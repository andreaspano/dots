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
# Colors are palette indices, not hex, so the prompt follows whatever the
# GNOME Terminal profile defines. The \[ \] wrappers mark them zero-width
# for readline; without them long lines wrap wrong and Ctrl-R redraws junk.
.pc() { printf '\[\e[38;5;%sm\]' "$1"; }
_PC_DIM="$(.pc 8)"    _PC_AMBER="$(.pc 11)"  _PC_BLUE="$(.pc 12)"
_PC_GREEN="$(.pc 10)" _PC_MAGENTA="$(.pc 13)" _PC_RED="$(.pc 9)"
_PC_FG="$(.pc 7)"     _PC_OFF='\[\e[0m\]'

# Nerd Font glyphs (JetBrainsMonoNL Nerd Font). If these ever show as boxes,
# the profile font has been changed to something without the icon range.
_PG_USER=$'' _PG_DIR=$'' _PG_GIT=$'' _PG_PY=$''

# ----- command timer -----
# DEBUG fires before every command; .prompt clears _PROMPT_T0 when it is done,
# so an empty Enter keypress reports no duration at all.
.timer_start() { [ -n "${_PROMPT_T0:-}" ] || _PROMPT_T0=$EPOCHREALTIME; }
trap '.timer_start' DEBUG

# Elapsed wall time of the last command, blank under 1s to keep the prompt
# quiet. Digits are extracted with [^0-9] rather than by splitting on "."
# because EPOCHREALTIME uses the LC_NUMERIC separator, a comma under it_IT.
.duration() {
  [ -n "${_PROMPT_T0:-}" ] || return 0
  local now="${EPOCHREALTIME//[^0-9]/}" t0="${_PROMPT_T0//[^0-9]/}"
  local ms=$(( (now - t0) / 1000 ))
  (( ms < 1000 )) && return 0
  if (( ms < 60000 )); then
    printf '%d.%01ds' $(( ms / 1000 )) $(( ms % 1000 / 100 ))
  else
    printf '%dm%02ds' $(( ms / 60000 )) $(( ms % 60000 / 1000 ))
  fi
}

.git_info() {
  # fast check
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

  local branch dirty n
  branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)" \
    || branch="$(git rev-parse --short HEAD 2>/dev/null)" \
    || branch="detached"

  n="$(git status --porcelain 2>/dev/null | wc -l)"
  (( n > 0 )) && dirty=" ●${n}"

  printf '%s %s%s' "$_PG_GIT" "$branch" "$dirty"
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


# Keeps $COLUMNS current, which the right-alignment below depends on.
shopt -s checkwinsize

.prompt() {
  # MUST be first
  local EXIT="$?"

  local dur git venv cwd host
  dur="$(.duration)"
  git="$(.git_info)"
  venv="$(venv_info)"; venv="${venv#(}"; venv="${venv%) }"
  cwd="${PWD/#$HOME/\~}"
  host="${HOSTNAME%%.*}"   # short name; FQDNs would eat the line

  # The top line is built as colored text alongside a running column count
  # rather than measuring the finished string: the Nerd Font icons occupy two
  # columns but are one character each, so ${#top} would under-count and skew
  # the padding. Every += therefore states its own width.
  local top="" cols=0 sep="${_PC_DIM} │ "

  top+="${_PC_AMBER}${_PG_USER}  ${USER}${_PC_DIM}@${_PC_AMBER}${host}"
  (( cols += 4 + ${#USER} + 1 + ${#host} ))
  top+="${sep}"                                   ; (( cols += 3 ))
  top+="${_PC_BLUE}${_PG_DIR}  ${cwd}"            ; (( cols += 4 + ${#cwd} ))
  [ -n "$git" ]  && { top+="${sep}${_PC_GREEN}${git}"          ; (( cols += 4 + ${#git} )); }
  [ -n "$venv" ] && { top+="${sep}${_PC_MAGENTA}${_PG_PY}  ${venv}"; (( cols += 7 + ${#venv} )); }

  # Command duration, right-aligned when there is room and dropped when not.
  local spaces pad
  if [ -n "$dur" ]; then
    pad=$(( ${COLUMNS:-80} - cols - ${#dur} - 1 ))
    if (( pad > 1 )); then
      printf -v spaces '%*s' "$pad" ''
      top+="${spaces}${_PC_AMBER}${dur}"
    fi
  fi

  # Status is a bare red cross on failure, nothing on success — the green
  # caret already says it went fine.
  local mark
  if (( EXIT != 0 )); then
    mark="${_PC_RED}✗ ❯"
  else
    mark="${_PC_GREEN}❯"
  fi

  # End on the body color so typed input starts clean
  PS1="${top}\n${mark} ${_PC_FG}"

  # Last: the DEBUG trap re-arms only once this is cleared
  unset _PROMPT_T0
}

# =========================
# Git identity (only if git exists)
# =========================
if command -v git >/dev/null 2>&1; then
  [ "$(git config --global user.email)" = "andrea@spano.it" ] || git config --global user.email "andrea@spano.it"
  [ "$(git config --global user.name)" = "andreaspano" ] || git config --global user.name "andreaspano"
fi

# ==========================
# dot files
# ==========================
ln -sfn "$HOME/dev/dots/vimrc" "$HOME/.vimrc"
ln -sfn "$HOME/dev/dots/bash_aliases" "$HOME/.bash_aliases"
ln -sfn "$HOME/dev/dots/tmux.conf" "$HOME/.tmux.conf"

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
eval "$(direnv hook bash)"
