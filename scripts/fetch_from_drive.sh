#!/usr/bin/env bash
# Download the challenge materials from Google Drive onto anvme.
# The Drive folder/file must be shared as "Anyone with the link - Viewer".
#
# Usage:
#   scripts/fetch_from_drive.sh <drive_folder_or_file_url> [dest_subdir]
#   dest_subdir defaults to "downloads" -> $HEAVY/downloads
set -euo pipefail
source "$(dirname "$0")/env.sh"

url=${1:?usage: fetch_from_drive.sh <drive_url> [dest_subdir]}
dest="$HEAVY/${2:-downloads}"
mkdir -p "$dest"
GDOWN="$HEAVY/envs/doctools/bin/gdown"

if [[ "$url" == *"/folders/"* ]]; then
  "$GDOWN" --folder --continue "$url" -O "$dest"
else
  ( cd "$dest" && "$GDOWN" --fuzzy --continue "$url" )
fi

echo
echo "Downloaded into $dest:"
find "$dest" -type f -printf '%10s  %p\n' | sort -k2
echo
echo "sha256 (paste into docs/ANVME_RECORD.md):"
find "$dest" -type f \( -name '*.zip' -o -name '*.tar*' \) -exec sha256sum {} \;
