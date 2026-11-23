# AI_Boost: Hackathon Workspace

ROS / Gazebo robotics challenge. Brief: [docs/CHALLENGE.md](docs/CHALLENGE.md).

## Storage rule

- **Here (`~/AI_Boost`, home, quota is tight):** code, configs, results, docs, submission.
- **anvme (`/anvme/workspace/v115be23-ai_boost`):** datasets, ROS workspace, Gazebo
  assets, rosbags, containers, envs, checkpoints, experiment outputs, caches.
- Every heavy item goes into [docs/ANVME_RECORD.md](docs/ANVME_RECORD.md).

## Layout

```
AI_Boost/
├── README.md
├── docs/            CHALLENGE.md, ANVME_RECORD.md (storage + experiment log)
├── src/             our code (python nodes, training, eval)
├── configs/         yaml / launch params
├── scripts/         env.sh, new_experiment.sh, update_storage_record.sh
├── notebooks/       analysis notebooks
├── results/         figures/, metrics/, tables/, <experiment_id>/NOTES.md
├── submission/      final deliverables
│
├── anvme        ->  workspace root
├── data         ->  anvme/data        (raw / processed / external)
├── ros_ws       ->  anvme/ros_ws      (src / build / install / log)
├── sim          ->  anvme/sim         (models / worlds / maps)
├── rosbags      ->  anvme/rosbags
├── tools        ->  anvme/tools       (third_party / containers)
├── envs         ->  anvme/envs
├── checkpoints  ->  anvme/checkpoints
└── experiments  ->  anvme/experiments
```

## Quick start

```bash
source ~/AI_Boost/scripts/env.sh                         # redirect all caches to anvme
scripts/new_experiment.sh baseline "first baseline run"  # new run + log entry
scripts/update_storage_record.sh                         # refresh sizes in the record
ws_extend ai_boost 90                                    # before 2027-02-20
```

anvme has no backups. Keep source code under git (push it somewhere), and copy final
results into `results/` or `submission/`.
