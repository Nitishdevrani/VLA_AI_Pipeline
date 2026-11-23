# AI_Boost: working rules

- Home quota is nearly full. Never put datasets, builds, envs, containers, rosbags,
  checkpoints or caches in this folder. They go on the anvme workspace
  `/anvme/workspace/v115be23-ai_boost`, reached through the symlinks (`data/`, `ros_ws/`, `sim/`,
  `rosbags/`, `tools/`, `envs/`, `checkpoints/`, `experiments/`).
- Run `source scripts/env.sh` before installs or runs so caches go to anvme.
- Every heavy item added to anvme gets a row in `docs/ANVME_RECORD.md`
  (Files & Datasets Inventory). New runs are started with `scripts/new_experiment.sh`,
  and their status is updated in the same doc.
- Results, figures, metrics and docs stay here, under `results/` and `docs/`.
- Challenge details: `docs/CHALLENGE.md`.
