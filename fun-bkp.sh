bkp() {
  local dry_run=false
  local show_progress=false

  case "${1:-}" in
    true|--dry-run|-n)
      dry_run=true
      ;;
    --progress)
      show_progress=true
      ;;
    "")
      ;;
    *)
      echo "Usage: bkp [true|--dry-run|-n|--progress]"
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

  local TIMESTAMP
  local REMOTE_DIR

  TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S")"
  REMOTE_DIR="${REMOTE_BASE_DIR}/${TIMESTAMP}"

  local RSYNC_OPTS=(
    -aHzr
    --human-readable
    --files-from="$INCLUDE_FILE"
    --exclude-from="$EXCLUDE_FILE"
    --relative
    -e "ssh -i $SSH_KEY"
  )

  if [ "$show_progress" = true ]; then
    RSYNC_OPTS+=(--info=progress2 --no-inc-recursive)
  fi

  if [ "$dry_run" = true ]; then
    RSYNC_OPTS+=(
      --dry-run
      --stats
    )

    echo "=== DRY RUN MODE ==="
    echo "Destination would be:"
    echo "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"
    echo

    local tmp_stats
    tmp_stats="$(mktemp)"

    rsync "${RSYNC_OPTS[@]}" \
      / "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" \
      | tee "$tmp_stats"

    echo
    echo "=== SIZE SUMMARY ==="
    grep -E \
      "Number of files:|Total file size:|Total transferred file size:" \
      "$tmp_stats"

    rm -f "$tmp_stats"

    echo
    echo "=== DRY RUN COMPLETED ==="
    return 0
  fi

  ssh -i "$SSH_KEY" "${REMOTE_USER}@${REMOTE_HOST}" \
    "mkdir -p '$REMOTE_DIR'"

  rsync "${RSYNC_OPTS[@]}" \
    / "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"

  ssh -i "$SSH_KEY" "${REMOTE_USER}@${REMOTE_HOST}" "
    cd '$REMOTE_BASE_DIR' &&
    ls -1dt */ 2>/dev/null | tail -n +$((KEEP_BACKUPS + 1)) | xargs -r rm -rf
  "

  echo "Backup completed at $(date)" >> "$LOG_FILE"
}
