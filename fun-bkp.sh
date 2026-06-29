bkp() {
  local dry_run=false

  case "${1:-}" in
    true|--dry-run|-n)
      dry_run=true
      ;;
    "")
      ;;
    *)
      echo "Usage: bkp [true|--dry-run|-n]"
      return 1
      ;;
  esac

  local REMOTE_USER="andrea"
  local REMOTE_HOST=192.168.1.2
  local REMOTE_BASE_DIR="/home/andrea/bkp"
  local INCLUDE_FILE="/home/andrea/.include.bkp"
  local EXCLUDE_FILE="/home/andrea/.exclude.bkp"
  local LOG_FILE="/home/andrea/.log.bkp"
  local SSH_KEY="$HOME/.ssh/id_rsa"
  local KEEP_BACKUPS=3
  local ASSUMED_SPEED_MBPS=50

  local TIMESTAMP
  local REMOTE_DIR

  TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S")"
  REMOTE_DIR="${REMOTE_BASE_DIR}/${TIMESTAMP}"

  local RSYNC_OPTS=(
    -aHr
    --human-readable
    --files-from="$INCLUDE_FILE"
    --exclude-from="$EXCLUDE_FILE"
    --relative
    -e "ssh -i $SSH_KEY"
  )

  local start_epoch=$SECONDS
  printf "  Started     : %s\n" "$(date +"%Y-%m-%d %H:%M:%S")"

  # ── Pre-flight: size + ETA ────────────────────────────────────────────────────
  local stats_out stats_err
  stats_err=$(mktemp)
  stats_out=$(rsync -aHr \
    --no-human-readable \
    --files-from="$INCLUDE_FILE" \
    --exclude-from="$EXCLUDE_FILE" \
    --relative \
    -e "ssh -i $SSH_KEY" \
    --dry-run --stats \
    / "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" 2>"$stats_err")

  local total_bytes
  total_bytes=$(printf '%s\n' "$stats_out" | \
    grep "Total transferred file size" | grep -oE '[0-9,]+' | tr -d ',')
  total_bytes=${total_bytes:-0}

  if [[ $total_bytes -eq 0 && -s "$stats_err" ]]; then
    echo "Pre-flight error:" >&2
    cat "$stats_err" >&2
  fi
  rm -f "$stats_err"

  local total_gb
  total_gb=$(awk "BEGIN {printf \"%.2f\", ${total_bytes} / 1073741824}")

  local est_seconds=$(( total_bytes / (ASSUMED_SPEED_MBPS * 1024 * 1024 + 1) ))
  local est_time
  est_time=$(printf "%02d:%02d:%02d" \
    $((est_seconds / 3600)) \
    $(( (est_seconds % 3600) / 60 )) \
    $((est_seconds % 60)))

  printf "  To transfer : %s GB\n" "$total_gb"
  printf "  Estimated   : %s  (assuming %d MB/s)\n\n" "$est_time" "$ASSUMED_SPEED_MBPS"

  if [ "$dry_run" = true ]; then
    echo "=== DRY RUN MODE ==="
    printf "  Destination : %s@%s:%s/\n\n" "$REMOTE_USER" "$REMOTE_HOST" "$REMOTE_DIR"
    echo "=== SIZE SUMMARY ==="
    printf '%s\n' "$stats_out" | \
      grep -E "Number of files:|Total file size:|Total transferred file size:"
    echo
    echo "=== DRY RUN COMPLETED ==="
    return 0
  fi

  ssh -i "$SSH_KEY" "${REMOTE_USER}@${REMOTE_HOST}" \
    "mkdir -p '$REMOTE_DIR'"

  # ── Live progress ────────────────────────────────────────────────────────────
  # rsync buffers progress internally when stdout is not a tty, so parsing its
  # output always yields stale data. Instead, poll the remote dir size via SSH.
  local tmp_out
  tmp_out=$(mktemp)

  { rsync "${RSYNC_OPTS[@]}" \
      / "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" >"$tmp_out" 2>&1 & } 2>/dev/null
  local rsync_pid=$!

  while kill -0 "$rsync_pid" 2>/dev/null; do
    local remote_bytes
    remote_bytes=$(ssh -i "$SSH_KEY" "${REMOTE_USER}@${REMOTE_HOST}" \
      "du -sb '${REMOTE_DIR}' 2>/dev/null | awk '{print \$1}'" 2>/dev/null)
    if [[ -n "$remote_bytes" && $remote_bytes -gt 0 && $total_bytes -gt 0 ]]; then
      local pct
      pct=$(awk "BEGIN {printf \"%d\", ${remote_bytes} * 100 / ${total_bytes}}")
      printf "\rProgresses [%d%%]   " "$pct"
    fi
    sleep 10
  done

  wait "$rsync_pid"
  local rsync_exit=$?
  printf "\n"

  if [[ $rsync_exit -ne 0 ]]; then
    echo "rsync failed (exit $rsync_exit):" >&2
    cat "$tmp_out" >&2
    rm -f "$tmp_out"
    return "$rsync_exit"
  fi
  rm -f "$tmp_out"

  ssh -i "$SSH_KEY" "${REMOTE_USER}@${REMOTE_HOST}" "
    cd '$REMOTE_BASE_DIR' &&
    ls -1dt */ 2>/dev/null | tail -n +$((KEEP_BACKUPS + 1)) | xargs -r rm -rf
  "

  local elapsed=$(( SECONDS - start_epoch ))
  local end_time
  end_time="$(date +"%Y-%m-%d %H:%M:%S")"
  printf "  Ended       : %s\n" "$end_time"
  printf "  Elapsed     : %02d:%02d:%02d\n" \
    $((elapsed / 3600)) $(( (elapsed % 3600) / 60 )) $((elapsed % 60))
  echo "Backup completed at $end_time" >> "$LOG_FILE"
}
