gemini() {
  local histfile="/tmp/gemini_history.txt"
  : > "$histfile"

  trap 'printf "\n\e[31mGame Over 💀\e[0m\n"; return 130' INT

  if [ -z "$GEMINI_API_KEY" ]; then
    printf '\e[31mERROR:\e[0m GEMINI_API_KEY is not set.\n'
    printf 'Run:\n  export GEMINI_API_KEY="your_key_here"\n'
    return 1
  fi

  if ! command -v curl >/dev/null 2>&1; then
    printf '\e[31mERROR:\e[0m curl is not installed.\n'
    return 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    printf '\e[31mERROR:\e[0m jq is not installed.\n'
    return 1
  fi

  printf '\n\e[1;38;5;110m🚀 Welcome to bashGemini\e[0m\n'
  printf '\e[2mPress Ctrl+C to exit\e[0m\n\n'

  while true; do
    read -e -r -p $'\e[32mgemini> \e[0m' prompt

    if [ "$prompt" = "exit" ]; then
      printf '\e[31mGame Over 💀\e[0m\n'
      break
    fi

    if [ "$prompt" = "help" ]; then
      printf '\e[38;5;110mAvailable commands:\e[0m\n'
      printf '\e[38;5;110m  help  - show this help message\e[0m\n'
      printf '\e[38;5;110m  reset - clear conversation history\e[0m\n'
      printf '\e[38;5;110m  exit  - quit bashGemini\e[0m\n\n'
      continue
    fi

    if [ "$prompt" = "reset" ]; then
      : > "$histfile"
      printf '\e[38;5;110mHistory cleared.\e[0m\n\n'
      continue
    fi

    [ -z "$prompt" ] && continue
    history -s "$prompt"

    local full_prompt
    full_prompt=$(
      printf "This is the conversation so far.\n"
      printf "Answer taking into account previous context.\n\n"
      cat "$histfile"
      printf "User: %s\nAssistant:" "$prompt"
    )

    local response
    response=$(
      curl -s -X POST \
        "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$GEMINI_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$(jq -n --arg txt "$full_prompt" '{
          contents: [
            {
              parts: [
                { text: $txt }
              ]
            }
          ]
        }')"
    )

    local answer
    answer=$(
      printf '%s' "$response" | jq -r '
        if .candidates and .candidates[0].content.parts then
          .candidates[0].content.parts
          | map(.text // "")
          | join("")
        elif .error then
          "ERROR: \(.error.message)"
        else
          "No response"
        end
      '
    )

    printf '\e[38;5;110m%s\e[0m\n\n' "$answer"

    {
      printf "User: %s\n" "$prompt"
      printf "Assistant: %s\n\n" "$answer"
    } >> "$histfile"
  done

  trap - INT
}
