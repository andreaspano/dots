bkp() {
  local REMOTE_USER="andrea"
  local REMOTE_HOST="mutolo"
  local REMOTE_BASE_DIR="/home/andrea/bkp"
  local INCLUDE_FILE="/home/andrea/.include.bkp"
  local EXCLUDE_FILE="/home/andrea/.exclude.bkp"
  local LOG_FILE="/home/andrea/.log.bkp"
  local SSH_KEY="$HOME/.ssh/id_rsa"

  local TIMESTAMP
  local REMOTE_DIR

  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  REMOTE_DIR="${REMOTE_BASE_DIR}/${TIMESTAMP}"

  ssh -i "$SSH_KEY" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p '$REMOTE_DIR'"

  rsync -avzr \
    --files-from="$INCLUDE_FILE" \
    --exclude-from="$EXCLUDE_FILE" \
    --relative \
    -e "ssh -i $SSH_KEY" \
    / "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"

  ssh -i "$SSH_KEY" "${REMOTE_USER}@${REMOTE_HOST}" "
    cd '$REMOTE_BASE_DIR' &&
    ls -1dt */ 2>/dev/null | tail -n +4 | xargs -r rm -rf
  "

  echo "Backup completed at $(date)" >> "$LOG_FILE"
}
