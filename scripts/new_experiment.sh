#!/usr/bin/env bash
# Create a new experiment: heavy run dir on anvme + light results dir here,
# and append a row to docs/ANVME_RECORD.md.
#
# Usage: scripts/new_experiment.sh <short_name> "<one-line description>"
set -euo pipefail
source "$(dirname "$0")/env.sh"

name=${1:?usage: new_experiment.sh <short_name> "<description>"}
desc=${2:-"(no description)"}
id="$(date +%Y%m%d_%H%M)_${name}"

mkdir -p "$EXP/$id"/{logs,outputs,rosbags,checkpoints} "$PROJ/results/$id"
cat > "$PROJ/results/$id/NOTES.md" <<EOF
# $id

- Description: $desc
- Heavy outputs: \`$EXP/$id\`
- Started: $(date '+%Y-%m-%d %H:%M')
- Config / command:
- Result / metrics:
- Conclusion:
EOF

python3 - "$PROJ/docs/ANVME_RECORD.md" "$id" "$desc" "$EXP/$id" <<'PY'
import sys, datetime
path, eid, desc, loc = sys.argv[1:]
marker = "<!-- EXPERIMENTS-END -->"
row = f"| {eid} | {datetime.date.today()} | {desc} | `{loc}` | running | [notes](../results/{eid}/NOTES.md) |\n"
text = open(path).read()
open(path, "w").write(text.replace(marker, row + marker, 1))
PY

echo "Experiment: $id"
echo "  heavy  -> $EXP/$id"
echo "  notes  -> $PROJ/results/$id/NOTES.md"
