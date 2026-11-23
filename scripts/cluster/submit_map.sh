#!/usr/bin/env bash
# Register a mapping run (new_experiment.sh) and submit it.   Usage: scripts/cluster/submit_map.sh [extra sbatch args]
set -euo pipefail
cd "$(dirname "$0")/../.."
source scripts/env.sh
out=$(scripts/new_experiment.sh cluster_map "Task 1 MAP run on a100mig (headless, Xvfb + Mesa, YOLO on MIG)")
id=$(echo "$out" | sed -n 's/^Experiment: //p')
job=$(sbatch --parsable --export=ALL,RUNDIR="$EXP/$id" "$@" scripts/cluster/map_run.sbatch)
sed -i "s|^- Config / command:.*|- Config / command: \`scripts/cluster/map_run.sbatch\`, Slurm job $job, log \`experiments/frasky_map_$job.log\`|" "results/$id/NOTES.md"
sed -i "s#| $id | \(.*\) | running |#| $id | \1 | queued (job $job) |#" docs/ANVME_RECORD.md
echo "$out"; echo "job $job"
