gpt() {
############################################################
# bashGPT - Minimal ChatGPT-like CLI using Codex
#
# Features:
# - Minimal interface (no Codex UI, clean output)
# - Conversation memory (context preserved across prompts)
# - Command history (↑ ↓ arrows enabled)
# - Colored prompt (green) and answers (soft blue)
# - Exit message with Ctrl+C or 'exit'
#
# Commands:
# - help  : show available commands
# - reset : clear conversation history
# - exit  : quit bashGPT
#
# Notes:
# - Uses Codex CLI in non-interactive mode (codex exec)
# - Requires Node.js and @openai/codex installed
# - No API key needed if logged in with ChatGPT
############################################################

  local histfile="/tmp/codex_min_history.txt"
  : > "$histfile"

  # Show message on Ctrl+C
  trap 'printf "\n\e[31mGame Over 💀\e[0m\n"; return 130' INT

  # Startup message
  printf '\n\e[1;38;5;110m🚀 Welcome to bashGPT\e[0m\n'
  printf '\e[2mPress Ctrl+C to exit\e[0m\n\n'

  while true; do
    read -e -r -p $'\e[32mgpt> \e[0m' prompt

    if [ "$prompt" = "exit" ]; then
      printf '\e[31mGame Over 💀\e[0m\n'
      break
    fi

    if [ "$prompt" = "help" ]; then
      printf '\e[38;5;110mAvailable commands:\e[0m\n'
      printf '\e[38;5;110m  help  - show this help message\e[0m\n'
      printf '\e[38;5;110m  reset - clear conversation history\e[0m\n'
      printf '\e[38;5;110m  exit  - quit bashGPT\e[0m\n\n'
      continue
    fi

    if [ "$prompt" = "reset" ]; then
      : > "$histfile"
      printf '\e[38;5;110mHistory cleared.\e[0m\n\n'
      continue
    fi

    [ -z "$prompt" ] && continue

    # Save input into bash history
    history -s "$prompt"

    # Build prompt with conversation memory
    local full_prompt
    full_prompt=$(
      printf "This is the conversation so far.\n"
      printf "Answer taking into account previous context.\n\n"
      cat "$histfile"
      printf "User: %s\nAssistant:" "$prompt"
    )

    # Run Codex in non-interactive mode
    local answer
    answer=$(
      NO_COLOR=1 TERM=dumb npx @openai/codex exec \
        --skip-git-repo-check \
        "$full_prompt" 2>/dev/null
    )

    # Print answer in soft blue
    printf '\e[38;5;110m%s\e[0m\n\n' "$answer"

    # Save conversation to local history
    {
      printf "User: %s\n" "$prompt"
      printf "Assistant: %s\n\n" "$answer"
    } >> "$histfile"
  done

  trap - INT
}
