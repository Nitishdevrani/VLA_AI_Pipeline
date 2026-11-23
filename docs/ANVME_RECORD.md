# anvme Storage & Experiment Record

The record of everything this project keeps on the anvme workspace. The project
folder (`~/AI_Boost`) holds only code, configs, results and docs. Anything large
lives on anvme and is linked in.

> ⚠️ **anvme is NOT backed up and the workspace expires.** Extend it before the
> expiry date with `ws_extend ai_boost 90` (10 extensions left). Copy final results
> and small key artifacts back into `results/` or `submission/`.

## Workspace

| Field | Value |
|-------|-------|
| Workspace ID | `ai_boost` |
| Path | `/anvme/workspace/v115be23-ai_boost` |
| Cluster | Alex (NHR@FAU), filesystem `anvme` |
| Created | 2026-11-22 |
| Expires | **2027-02-20** (90 days, extendable) |
| Find it | `ws_find ai_boost` |
| Extend | `ws_extend ai_boost 90` |

## Layout

| anvme path | Symlink in project | Purpose |
|------------|--------------------|---------|
| `data/raw` | `data/raw` | Original challenge dataset, never modified |
| `data/processed` | `data/processed` | Preprocessed / converted data |
| `data/external` | `data/external` | Extra third-party datasets |
| `ros_ws/{src,build,install,log}` | `ros_ws/` | ROS (colcon) workspace |
| `sim/{models,worlds,maps}` | `sim/` | Gazebo models, worlds, maps |
| `rosbags/` | `rosbags/` | Recorded / provided rosbags |
| `tools/third_party` | `tools/` | Cloned external repos and tools |
| `tools/containers` | `tools/` | Apptainer/Singularity images (ROS, Gazebo) |
| `envs/` | `envs/` | conda / venv environments |
| `checkpoints/` | `checkpoints/` | Model weights |
| `experiments/<id>/` | `experiments/` | Per-run logs, outputs, bags, checkpoints |
| `downloads/` | — | Raw downloaded archives (zips) before extraction |
| `cache/` | — | pip / HF / torch / apptainer / ROS log caches (set by `scripts/env.sh`) |

## Files & Datasets Inventory

Add a row whenever something heavy is placed on anvme.

| Item | anvme path | Source / origin | Size | Added | Notes |
|------|-----------|-----------------|------|-------|-------|
| _example: challenge dataset v1_ | `data/raw/...` | _URL / organizer_ | _GB_ | _YYYY-MM-DD_ | _checksum, format_ |
| Challenge bundle (Drive) | `downloads/ws_ai_boost-challenge_1.zip` | Google Drive `AIBoost` folder (organizer bundle) | 14.1 GB | 2026-11-22 | sha256 `9991472d…75591593`. Contents moved out (see below) |
| Grapes dataset zip | `downloads/Grapes_Dataset.zip` | from bundle | 4.95 GB | 2026-11-22 | sha256 `4b262a8f…7ccec4a56` |
| Grapes dataset (unzipped) | `data/raw/Grapes_Dataset/` | from Grapes_Dataset.zip | 4.8 GB | 2026-11-22 | **10,905 imgs** (README says 11,007) + 10,907 YOLO txt. wgsid 300, AI4A 247, wGrape 247, without_Bunches **102** (README says 204), grapevine 10,009 (10,010 labels). Do not modify |
| Frasky simulator folder | `sim/Frasky_Vineyard_simulator/` | from bundle | 9.1 GB | 2026-11-22 | compose.yaml, start_sim.sh, nav/mapping JSONs, my_pkgs/. Small files copied to `docs/source/simulator/` |
| Frasky Docker image | `sim/Frasky_Vineyard_simulator/frasky_test.tar.gz` | from bundle | 9.1 GB | 2026-11-22 | sha256 `4119d460…79076d7`. linux/amd64, ROS Noetic |
| Frasky Apptainer image | `tools/containers/frasky_test.sif` | gunzip → untar OCI layout → `apptainer build … oci://<dir>` (docker-archive/oci-archive readers fail on this Docker-25+ save) | 8.96 GB | 2026-11-22 | Run with `--no-mount home,bind-paths --no-home`, because host /home hides the container's /home/frasky_ws_container |
| Sim files extracted from image | `sim/extracted/` | copied out of the SIF | <1 MB | 2026-11-22 | vineyard.world, keepout yaml, label generator, `grapes_ground_truth.json` (270 grapes, world and map frame) |
| doctools venv (PyMuPDF 1.26.5) | `envs/doctools` | pip | ~60 MB | 2026-11-22 | PDF extraction + gdown 5.2.2 for Drive downloads |

## Experiments

Rows are appended automatically by `scripts/new_experiment.sh`. Update the status
(`running` → `done` / `failed` / `abandoned`) and fill in the notes file.

| ID | Date | Description | anvme location | Status | Notes |
|----|------|-------------|----------------|--------|-------|
| smoke_5045186 | 2026-11-22 | Headless sim smoke test on a100mig (Xvfb + Mesa) | `experiments/smoke_5045186/`, `experiments/frasky_smoke_5045186.log` | failed: roslaunch could not resolve `localhost` (empty /etc/hosts after `--no-mount bind-paths`) | `scripts/cluster/sim_smoketest.sbatch` |
| smoke_5045806 | 2026-11-22 | Re-run with own /etc/hosts bind and HOME set in-shell | `experiments/smoke_5045806/`, `experiments/frasky_smoke_5045806.log` | ran: 186 topics, all 7 routines, camera 30 Hz, RTF 0.52; frame is untextured grey (open issue) | `scripts/cluster/sim_smoketest.sbatch` |
| 20261123_1948_cluster_map | 2026-11-23 | Task 1 MAP run on a100mig (headless, Xvfb + Mesa, YOLO on MIG) | `/anvme/workspace/v115be23-ai_boost/experiments/20261123_1948_cluster_map` | cancelled (job 5058054): map folder copy ran without anvme bind, fixed | [notes](../results/20261123_1948_cluster_map/NOTES.md) |
| 20261123_1949_cluster_map | 2026-11-23 | Task 1 MAP run on a100mig (headless, Xvfb + Mesa, YOLO on MIG) | `/anvme/workspace/v115be23-ai_boost/experiments/20261123_1949_cluster_map` | done (job 5058055): MAP ran, 0 grapes stored (estimator saved nothing) | [notes](../results/20261123_1949_cluster_map/NOTES.md) |
| 20261123_2033_cluster_map | 2026-11-23 | Task 1 MAP run on a100mig (headless, Xvfb + Mesa, YOLO on MIG) | `/anvme/workspace/v115be23-ai_boost/experiments/20261123_2033_cluster_map` | cancelled (job 5058215): detector crashed at import (cv_bridge) after GPU lib path was prepended; diagnostics in outputs/diag_5min.txt | [notes](../results/20261123_2033_cluster_map/NOTES.md) |
| 20261123_2049_cluster_map | 2026-11-23 | Task 1 MAP run on a100mig (headless, Xvfb + Mesa, YOLO on MIG) | `/anvme/workspace/v115be23-ai_boost/experiments/20261123_2049_cluster_map` | cancelled (job 5058275): detector still on CPU (appended lib path loads wrong libcuda); crop_data had 0 boxes in 64 msgs sampled | [notes](../results/20261123_2049_cluster_map/NOTES.md) |
| 20261123_2105_cluster_map | 2026-11-23 | Task 1 MAP run on a100mig (headless, Xvfb + Mesa, YOLO on MIG) | `/anvme/workspace/v115be23-ai_boost/experiments/20261123_2105_cluster_map` | done (job 5058359): baseline pipeline, 226/270 real grapes (83.7 %), IDs not sim numbers | [notes](../results/20261123_2105_cluster_map/NOTES.md) |
<!-- EXPERIMENTS-END -->

## Auto Inventory (sizes)

Generated by `scripts/update_storage_record.sh`. Do not edit by hand.

<!-- INVENTORY-START -->
_Last refreshed: 2026-11-22 04:44_

```
id: ai_boost
     workspace directory  : /anvme/workspace/v115be23-ai_boost
     remaining time       : 89 days 23 hours
     comment              : AI_Boost hackathon: datasets, ROS/Gazebo, heavy artifacts
     creation time        : Sun Nov 22 04:43:19 2026
     expiration date      : Sat Feb 20 04:43:19 2027
     filesystem name      : anvme
     available extensions : 10
```

| Path | Size | Files |
|------|------|-------|
| `cache` | 36K | 0 |
| `checkpoints` | 4.0K | 0 |
| `data` | 16K | 0 |
| `envs` | 4.0K | 0 |
| `experiments` | 4.0K | 0 |
| `ros_ws` | 20K | 0 |
| `rosbags` | 4.0K | 0 |
| `sim` | 16K | 0 |
| `tools` | 12K | 0 |
| `data/external` | 4.0K | 0 |
| `data/processed` | 4.0K | 0 |
| `data/raw` | 4.0K | 0 |

**Total:** 120K
<!-- INVENTORY-END -->
