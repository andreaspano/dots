#!/bin/bash
set -euo pipefail

REMOTE_USER="andrea"
REMOTE_HOST="mutolo"
REMOTE_BASE_DIR="/home/andrea/bkp"
INCLUDE_FILE="/home/andrea/adrive/include.bkp"
EXCLUDE_FILE="/home/andrea/adrive/exclude.bkp"
LOG_FILE="/home/andrea/adrive/log.bkp"
SSH_KEY="$HOME/.ssh/id_rsa"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REMOTE_DIR="${REMOTE_BASE_DIR}/${TIMESTAMP}"

ssh -i "$SSH_KEY" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p '$REMOTE_DIR'"

rsync -avzr \
  --files-from="$INCLUDE_FILE" \
  --exclude-from="$EXCLUDE_FILE" \
  --relative \
  -e "ssh -i $SSH_KEY" \
  / "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" \
  >> "$LOG_FILE" 2>&1

ssh -i "$SSH_KEY" "${REMOTE_USER}@${REMOTE_HOST}" "
  cd '$REMOTE_BASE_DIR' &&
  ls -1dt */ 2>/dev/null | tail -n +4 | xargs -r rm -rf
"

echo "Backup completed at $(date)" >> "$LOG_FILE"
