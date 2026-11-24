# 20261124_0209_laptop_map

- Description: Task 1 MAP run on the Linux laptop (RTX 5070 hybrid, Docker). Organizers' pipeline
  unchanged (their YOLO weights, crop estimator, map DB, MAP route), so this is a **baseline
  reproduction**, not our method. YOLO on CPU.
- Setup: `configs/linux/sim_up.sh --rtf 0.12` (gzserver on Xvfb + Mesa, Gazebo window on the real
  display), `mapping.launch`, then `src/frasky_mission/routine.py HOMING MAP`, then mapping nodes
  stopped with SIGINT as in the README. Detection lag (`rostopic delay .../crop_data`) 0.028 s.
- Started: 2026-11-24 02:09. MAP took 4,260 s wall / 511 s sim.
- Files: `test_mapping.json` (the MAP output), `metrics.json` (score_mapping.py), `routines.jsonl`.
- Result: 246 entries. Official count 246/270 = 91.1 %. Verified 230 distinct real grapes = 85.2 %.
  4 duplicates, 12 entries that match no grape. Mean position error 5.6 cm (max 13 cm).
  IDs are sequential; none equals the simulator number.
  YOLO: 15,921 frames, 5,245 with grapes.

  | Row side (sim IDs) | 1-45 | 46-90 | 91-135 | 136-180 | 181-225 | 226-270 |
  |---|---|---|---|---|---|---|
  | this run (laptop, CPU YOLO, RTF 0.12) | 43 | 44 | **24** | 44 | 31 | 44 |
  | cluster baseline 20261123_2105 (GPU YOLO) | 35 | 44 | **24** | 44 | 35 | 44 |

- Conclusion: the laptop reproduces the cluster baseline (230 vs 226 real grapes). Side 91-135 is
  stuck at 24/45 in both runs, so the loss there is systematic (route / camera geometry), not
  detector noise. Side 181-225 varies run to run (31 vs 35). The 12 unmatched entries count toward
  the official score but are not real grapes; check them before any submission.
- Earlier failed attempts the same night (not kept): RTF 0.9 with NVIDIA PRIME rendering -> frozen
  camera, 0 detections; Xvfb at RTF 0.3 -> YOLO lag 0.43 s, estimator never fired, empty JSON.
  Both causes are in docs/LINUX_SETUP.md.
