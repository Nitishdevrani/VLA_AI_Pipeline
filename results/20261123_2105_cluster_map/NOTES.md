# 20261123_2105_cluster_map

- Description: Task 1 MAP run on a100mig (headless, Xvfb + Mesa, YOLO on MIG)
- Heavy outputs: `/anvme/workspace/v115be23-ai_boost/experiments/20261123_2105_cluster_map`
- Started: 2026-11-23 21:05
- Config / command: `scripts/cluster/map_run.sbatch`, Slurm job 5058359, log `experiments/frasky_map_5058359.log`
- Result / metrics: organizers' pipeline (their YOLO weights, estimator, MAP route), detector on MIG GPU. 229 entries, 226 distinct real grapes = 83.7 % (official count 229/270 = 84.8 %), 1 duplicate, 2 unmatched, mean position error 5.5 cm (max 8.6). IDs are sequential, none equals the simulator number. Per row side (sim IDs): 1-45:35, 46-90:44, 91-135:24, 136-180:44, 181-225:35, 226-270:44. MAP took 1637 s wall / 480 s sim. metrics.json alongside.
- Conclusion: BASELINE ONLY (no code of ours in the pipeline). Gaps: sides 91-135 (24/45), 1-45 and 181-225 (35/45); IDs do not match sign numbers.
