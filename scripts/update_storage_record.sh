#!/usr/bin/env bash
# Refresh the auto-generated inventory section of docs/ANVME_RECORD.md
# (sizes, file counts, workspace expiry). Run after adding/removing heavy data.
set -euo pipefail
source "$(dirname "$0")/env.sh"
doc="$PROJ/docs/ANVME_RECORD.md"

tmp=$(mktemp)
{
  echo "_Last refreshed: $(date '+%Y-%m-%d %H:%M')_"
  echo
  echo '```'
  ws_list 2>/dev/null | grep -A7 'id: ai_boost' || echo "workspace ai_boost not found"
  echo '```'
  echo
  echo "| Path | Size | Files |"
  echo "|------|------|-------|"
  for d in "$HEAVY"/* "$HEAVY"/data/* "$HEAVY"/experiments/*; do
    [ -d "$d" ] || continue
    size=$(du -sh "$d" 2>/dev/null | cut -f1)
    files=$(find "$d" -type f 2>/dev/null | wc -l)
    echo "| \`${d#$HEAVY/}\` | $size | $files |"
  done
  echo
  echo "**Total:** $(du -sh "$HEAVY" 2>/dev/null | cut -f1)"
} > "$tmp"

python3 - "$doc" "$tmp" <<'PY'
import sys, re
doc, tmp = sys.argv[1:]
text = open(doc).read()
new = open(tmp).read()
text = re.sub(r"(<!-- INVENTORY-START -->\n).*?(<!-- INVENTORY-END -->)",
              lambda m: m.group(1) + new + m.group(2), text, flags=re.S)
open(doc, "w").write(text)
PY
rm -f "$tmp"
echo "Updated $doc"
