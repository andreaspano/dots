# ---------------------------------------------------------------------------
# excalidraw_start — starts the mcp_excalidraw canvas and checks the MCP
# integration with Claude Code.
#
# Installation: paste this block into ~/.bashrc (or ~/.zshrc), then:
#   source ~/.bashrc
#
# Usage:
#   excalidraw_start                # uses ~/mcp_excalidraw as default
#   excalidraw_start /other/path    # custom path to the cloned repo
#   excalidraw_stop                 # stops the canvas
# ---------------------------------------------------------------------------

exstart() {
  local repo_dir="${1:-$HOME/mcp_excalidraw}"
  local port="${PORT:-3000}"
  local canvas_url="http://127.0.0.1:${port}"
  local health_url="${canvas_url}/health"
  local log_file="/tmp/excalidraw-canvas.log"
  local pid_file="/tmp/excalidraw-canvas.pid"
  local max_wait=20

  local green='\033[0;32m'
  local red='\033[0;31m'
  local yellow='\033[1;33m'
  local nc='\033[0m'

  # 0. Preliminary checks
  if [ ! -d "$repo_dir" ]; then
    echo -e "${red}[ERROR]${nc} Repo not found at: $repo_dir"
    echo "  Clone it with: git clone https://github.com/yctimlin/mcp_excalidraw.git $repo_dir"
    return 1
  fi

  if [ ! -d "$repo_dir/dist" ]; then
    echo -e "${red}[ERROR]${nc} Build not found (missing $repo_dir/dist)."
    echo "  Run first: cd $repo_dir && npm ci && npm run build"
    return 1
  fi

  # 1. Canvas already running?
  if curl -fs "$health_url" > /dev/null 2>&1; then
    echo -e "${green}[OK]${nc} Canvas server already running at $canvas_url"
  else
    echo -e "${green}[OK]${nc} Starting canvas server (port $port)..."
    (
      cd "$repo_dir" || return 1
      PORT="$port" nohup npm run canvas > "$log_file" 2>&1 &
      echo $! > "$pid_file"
    )

    local waited=0
    until curl -fs "$health_url" > /dev/null 2>&1; do
      sleep 1
      waited=$((waited + 1))
      if [ "$waited" -ge "$max_wait" ]; then
        echo -e "${red}[ERROR]${nc} Canvas isn't responding after ${max_wait}s. Log:"
        echo "  tail -n 50 $log_file"
        return 1
      fi
    done
    echo -e "${green}[OK]${nc} Canvas server started (PID $(cat "$pid_file" 2>/dev/null || echo '?')), log at $log_file"
  fi

  # 2. Check MCP registration in Claude Code
  if command -v claude > /dev/null 2>&1; then
    if claude mcp list 2>/dev/null | grep -qi excalidraw; then
      echo -e "${green}[OK]${nc} MCP server 'excalidraw' is already registered in Claude Code."
    else
      echo -e "${yellow}[!]${nc} MCP server 'excalidraw' is not registered."
      echo "  Register it with:"
      echo "    claude mcp add excalidraw --scope user \\"
      echo "      -e EXPRESS_SERVER_URL=$canvas_url \\"
      echo "      -e ENABLE_CANVAS_SYNC=true \\"
      echo "      -- node $repo_dir/dist/index.js"
    fi
  else
    echo -e "${yellow}[!]${nc} 'claude' command not found in PATH."
  fi

  # 3. Open the browser
  if command -v xdg-open > /dev/null 2>&1; then
    xdg-open "$canvas_url" > /dev/null 2>&1 &
    echo -e "${green}[OK]${nc} Browser opened at $canvas_url"
  else
    echo -e "${yellow}[!]${nc} xdg-open not available. Open manually: $canvas_url"
  fi

  echo ""
  echo -e "${green}[OK]${nc} All set. Canvas: $canvas_url — Log: $log_file"
  echo "To stop: excalidraw_stop"
}

exkill() {
  local pid_file="/tmp/excalidraw-canvas.pid"
  if [ -f "$pid_file" ] && kill "$(cat "$pid_file")" 2>/dev/null; then
    echo "Canvas server stopped (PID $(cat "$pid_file"))."
    rm -f "$pid_file"
  else
    echo "No active canvas server (or invalid PID). Trying pkill fallback..."
    pkill -f "npm run canvas" 2>/dev/null && echo "Stopped via pkill." || echo "Nothing to stop."
  fi
}
