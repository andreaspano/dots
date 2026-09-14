# Sync a public Google Drive folder <> local dir (bidirectional)
#
# Usage: ssync <drive-folder-url> [local-dir]
#   ssync https://drive.google.com/drive/folders/1CHLX_U-0QtODWm4CrGQYjRAf413Mds7P
#
# First run on a given folder needs a baseline: add --resync once, e.g.
#   rclone bisync --drive-root-folder-id <id> pdrive: <dest> --resync

ssync() {
  local url="$1"
  if [[ -z "$url" ]]; then
    echo "usage: ssync <drive-folder-url> [local-dir]"
    return 1
  fi

  local id
  id=$(echo "$url" | grep -oP '(?<=folders/)[^/?]+')
  if [[ -z "$id" ]]; then
    echo "ssync: could not extract folder id from url"
    return 1
  fi

  local dest="${2:-$HOME/prj}"
  mkdir -p "$dest"
  rclone bisync --drive-root-folder-id "$id" pdrive: "$dest" --create-empty-src-dirs -v --fast-list
}
