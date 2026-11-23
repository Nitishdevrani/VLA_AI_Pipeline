# 20261123_1949_cluster_map

- Description: Task 1 MAP run on a100mig (headless, Xvfb + Mesa, YOLO on MIG)
- Heavy outputs: `/anvme/workspace/v115be23-ai_boost/experiments/20261123_1949_cluster_map`
- Started: 2026-11-23 19:49
- Config / command: `scripts/cluster/map_run.sbatch`, Slurm job 5058055, log `experiments/frasky_map_5058055.log`
- Result / metrics: MAP routine done (2179 s wall, 527 s sim) but test_mapping.json empty: 272 frames had YOLO detections, estimator never stored a grape. Diagnosed in the next run.
- Note: detector ran on CPU (~1.3 s/frame, RTF fell 0.41 -> 0.22) because the image ENV hid the --nv libs; fixed in map_run.sbatch for later runs (GPUENV).
- Conclusion:
