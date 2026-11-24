# Challenge Brief: AI-BOOST × Frasky

**GenAI-based natural-language mission generator for autonomous robots in agriculture.**
Challenge owners: Intellimech and JOiiNT LAB (Bergamo). EU AI-BOOST open competition.

Source documents are in [docs/source/](source/): the challenge slides, the Frasky README v2.0
and the dataset README. Plain-text extracts sit next to each PDF.

## 1. The task in one paragraph

Build a system that turns a user instruction (voice or text, e.g. *"spray grape 8"*) into a
correct, ROS-1-compatible **Frasky mission**: a sequence of navigation, perception and
manipulation routine calls. The system then runs that mission on the Frasky digital twin in
the Gazebo vineyard. There are three missions:

| # | Mission | What the robot does | Score |
|---|---------|---------------------|-------|
| 1 | **Grape mapping** | Drive the vineyard, detect and localize every grape, write a JSON (id, confidence, grape_pose, robot_pose, grasping_pose) | % of the **270** sim grapes in the output JSON |
| 2 | **Monitoring** | For every mapped grape: NAV to its `robot_pose`, then APPROACH and take an image | % of mapped grapes correctly imaged (sim number must be visible) |
| 3 | **Precision task** | NAV to one given grape ID, then SPRAY | Pass / fail |

## 2. Robot & simulator

- **Frasky** = Clearpath Husky A-200 base + Franka FR3 7-DoF arm. The end-effector carries
  a RealSense D415, a spray nozzle and a qb SoftHand.
- **Software:** Ubuntu 20.04, **ROS 1 Noetic**, shipped as a Docker image (`frasky_test.tar.gz`).
  Gazebo vineyard: **3 rows, 16 × 10 m, 270 grapes**, textured with real grape images.
  The reference PC was an i7-12700H with an RTX 3060 (6 GB), 32 GB RAM and Docker 28.
- **Shared materials:** `Documents/`, `Frasky_Vineyard_simulator/`, `Grapes_Dataset/`.
  - `husky_nav_out.json` holds the waypoints for the navigation input.
  - `mapping_first_row.json` **as actually shipped** has **45 entries, IDs 181–225**, which is one side of one row.
    The robot sits at y = 1.24, and x runs from −2.61 to −12.45 in 0.225 m steps. These entries are incomplete:
    `grape_pose` and `grasping_pose` are all zeros, and the robot quaternion is `w = 0`, which is invalid. The
    orchestrator must replace it with a valid heading before publishing a NAV target. The 22-ID list in the
    README PDF is from an older example.
  - **Layout inferred from this:** 270 = **3 rows × 2 sides × 45 grapes**. IDs are probably 1–270, with 45 per side.
  - `husky_nav_out.json` (22 base waypoints) snakes through all **4 corridors** (y ≈ −1.8, 1.3, 4.3, 6.8).
    It drives the two inner corridors in both directions, which covers **all 6 row sides** for a side-looking camera.
    So mapping coverage is limited by detection and tracking quality, not by the route.
  - `test_mapping.json` ships empty (`[]`). It is bind-mounted, and `MAP` writes its output there.
  - Copies of the small simulator files are in `docs/source/simulator/`.
- **Start / stop:** `docker load --input frasky_test.tar.gz`, then `source start_sim.sh`, then
  `frasky_sim_start`. Stop with `frasky_sim_stop`, `exit`, then `docker stop frasky_test`.

## 2b. Inside the image (read from the SIF, 22 Nov)

- **Ground truth exists.** `frasky_simulation/worlds/vineyard.world` defines **`grape_1` … `grape_270`**. Each has
  a two-sided **green ID sign with 7-segment digits** (`scripts/generate_grape_labels.py`). That sign is the "simulator
  number" that must be visible in the monitoring photos. Parsed poses are in
  `docs/source/simulator/grapes_ground_truth.json`, in both the world and the map frame.
- **World → map transform:** the map/odom origin is the robot spawn, (−7.5, 2.5) with yaw 3.14 in the world.
  So map_x = −(wx + 7.5) and map_y = −(wy − 2.5). This was checked against `mapping_first_row.json`: ID 181 has
  grape map x = −2.613 and baseline robot x = −2.613.
- **ID layout in the map frame:** 6 faces × 45 grapes, x from −2.61 to −12.46, 0.225 m spacing, all at z = 1.15.

  | Map y | Grape IDs |
  |-------|-----------|
  | 6.1 | 1–45 |
  | 4.9 | 46–90 |
  | 3.1 | 91–135 |
  | 1.9 | 136–180 |
  | 0.1 | 181–225 (the baseline file) |
  | −1.1 | 226–270 |

  Baseline robot poses sit 1.12 m beside each grape in the corridor.
- **Rule for us:** use the ground truth **only to evaluate** our own mapping (recall, localization error, ID
  matching). Never write it into a submitted JSON. The task is to *detect and localize* grapes, and organizers can
  tell copied poses apart from real ones.
- **Launch:** `frasky_sim_start` is an alias that runs `roslaunch frasky_simulation frasky_simulation.launch` in terminator.
  Useful arguments: `gui`, `rviz`, `joystick`, `paused`, `ideal_navigation` (default true, which uses Gazebo ground-truth pose),
  and `navigation_map` (`frasky_maps/test_6.yaml`). For headless runs:
  `gui:=false rviz:=false joystick:=false`.
- The image also contains the organizers' developer leftovers (`.bash_history`, `.ssh`, `.codex`). Don't use them.

## 3. ROS interface (what our orchestrator must drive)

**Main service:** `/robot_frasky/Routine` (`jntlb_fwk_msgs/SetName`, field `name`). Valid names:
`MAP, NAV, APPROACH, GRASP, SPRAY, HOMING, BASE_HOME`.
The empty response only means "accepted". Completion is when
`/robot_frasky/routine_status` (`std_msgs/Bool`) goes **false → true → false**.

| Item | Type | Use |
|------|------|-----|
| `/orchestrator/robot_pose` | `geometry_msgs/PoseStamped`, `frame_id: robot_pose` | NAV target. Must be published **continuously** (the README example uses `-r 100`) before and during `NAV` |
| `/robot_frasky/routine_status` | `std_msgs/Bool` | Routine done-detection |
| `/auto2ark/robot_state` | `std_msgs/Int64` | Base state: -1 idle, 1 accepted, 2/3 moving, 4 rejected, 6/7 error |
| `/robot_frasky/active_replay` | `std_msgs/Bool` | True while an arm trajectory is executing |
| `/robot_frasky/camera/color/image_raw` | `sensor_msgs/Image` | RGB. **Source for monitoring photos** |
| `/robot_frasky/camera/depth/color/points` | `sensor_msgs/PointCloud2` | Depth |
| `/robot_frasky/detection_img` | `sensor_msgs/Image` | Annotated detections (diagnostic) |
| `/robot_frasky/frasky_detection/crop_data` | `frasky_detection/TrackingData` | YOLO boxes with ids |
| `/robot_frasky/frasky_detection/closest_grape_pose` | `PoseStamped` | Nearest grape in the camera frame |
| `/robot_frasky/franka_ee_pose`, `/right_hand_measurement` | PoseStamped / Float64 | Arm readiness |
| `/robot_frasky/RoutineExit`, `/auto2ark/cancelGoal` | `std_srvs/Empty` | Stop (careful: calling RoutineExit while idle aborts the *next* routine) |
| `/robot_frasky/frasky_detection/store_crop_map` | `frasky_detection/CropMap` | Writes `<time>_<name>.json`, `_filtered.json` (conf > 0.7 and w ≠ 0) and `_filtered_pose.json` |

**Launch files** (in the container, package `frasky_detection`):

- `mapping.launch` starts `yolo_tracking`, `crop_estimator_x_coord` and `crop_map_db`.
  Output goes to `crop_map_db/test_mapping.json`.
- `navigation.launch` starts `yolo_tracking_no_labels` and `active_perception`.

**Detector parameters worth tuning:** `confidence` 0.7, `confidence_min` 0.01,
`attention_threshold` 2.0 s, `grape_distance_max_to_update` 2.0 m.

**Mission recipes:**

- **Mapping:** start `mapping.launch`, call `HOMING`, call `MAP`, wait for completion, kill the launch, then export the JSON.
- **Monitoring:** start `navigation.launch`. Then for each JSON entry in file order: publish its `robot_pose`, call `NAV`, wait, call `APPROACH`, wait, and capture the image. Finish with `BASE_HOME` and kill the launch.
- **Precision:** run the same NAV sequence for one ID, then call `SPRAY` and wait. The ID comes from `randomizer.sh <json>`.

## 4. KPIs (final evaluation)

| KPI | Target |
|-----|--------|
| 1. Intent recognition accuracy (task, objects, location, constraints) | ≥ 90 % |
| 2. Task planning and execution success (ROS sequence vs. reference, run in sim) | ≥ 85 % |
| 3. Robustness to 3–5 paraphrases per mission | ≥ 85 % |
| 4. Latency, speech to ROS mission (bonus) | 5–10 s |
| 5. Task completion time (bonus) | lower is better |

## 5. Dataset (`Grapes_Dataset`)

- 11,007 RGB images, single class `0 = grape`, YOLO txt (`cls cx cy w h`, normalized).
- Subsets:

  | Subset | Images | Notes |
  |--------|--------|-------|
  | wgsid (CDY/CFR/CSV/SVB/SYH) | 300 | 2048×1365 |
  | AI4A Tempranillo | 247 | |
  | wGrape | 247 | Plus 204 negatives without bunches |
  | grapevine | 10,009 | 720×540 |

- Known issues: sun reflections, leaf or pipe occlusion, trunk-like colours, fallen grapes,
  and grapes from the next row back.
- **Licences are mixed.** WGISD is CC BY-NC 4.0, AI4A is Apache 2.0, Grapevine is CC BY 4.0, and
  wGrapeUNIPD is CC BY-NC-ND. That is fine for this competition, but cite all four.
- **Actual counts as shipped:** 10,905 images and 10,907 label files. `wGrape/without_Bunches` has only **102** negatives, not 204, which accounts for the gap to 11,007. `grapevine` has one orphan label.
- **Use:** fine-tune or replace the container's YOLO for better mapping recall. Note that the
  grapevine subset dominates, at 91 % of the images.

## 5b. Official rules that matter (website, Annex 2, applicant guidelines)

Sources are in `docs/source/`: `Challenge1_Description_Annex2.pdf`, `AIBOOST_Guidelines_for_Applicants.pdf`,
and the website <https://aiboost-project.eu/ai-challenge-competition/> plus its FAQ.

- **A VLA model is a challenge-owner requirement.** The FAQ says solutions without one "will be penalised".
  Speech, text, visual data and maps must all feed the mission generator. Scope is
  *high-level* mission generation, not low-level continuous control.
- **Objectives (Annex 2):**
  1. Speech to text.
  2. LLM intent recognition and task decomposition.
  3. ROS-compatible mission plans.
  4. Visual and map context.
  5. Validation on the robot platform.
- **Baseline to beat:** the GUI / manual / rule-based robot programming that is current practice.
- **Primary metrics:** Execution Success Rate and Mission Generation Time.
  **Secondary metrics:** reliability, usability (ease of integration) and transparency (interpretable plan
  descriptions). Safety requirements: validate commands before execution, fail-safes, e-stop and human oversight.
- **Final score (Advance phase):**

  | Component | Weight |
  |-----------|--------|
  | **Final Report** | **50 %** (60 % technical performance and docs, 25 % innovation, rest responsible AI and efficiency) |
  | Final algorithm automatic scoring | 25 % |
  | Pitch and live demo | 20 % |
  | Audience vote | 5 % |

- **Mid-Term Checkpoint (Dec 2026)** is **pass/fail**. Passing releases the remaining 50 % of the Spark prize.
  **Monthly submissions** feed an automatic-scoring leaderboard. The 25 Nov report is one of these.
- **Final submission:** algorithm, Final Report and pitch, **15 days before** the Brussels event (Feb 2027).
- **Prizes:** €100k to the Advance winner, plus €12.5k Innovation Excellence and €12.5k Responsible AI awards.
- **IP:** we keep ownership. The challenge owner gets a 6-month exclusive, royalty-free use right afterwards.
- **Compute:** optional CINECA Leonardo access, which the proposal requested: 1,500 A100 GPU-hours.
- Licence note: Annex 2 lists AI4Agriculture as **MIT**, while the dataset README says **Apache 2.0**. Both are permissive.

## 5c. Our proposal: VinePilot (UTN FunAI, Prof. Asano). Priority, but not binding

Source: `docs/source/AI_Boost_VinePilot_application.pdf`.

**Architecture** (five modules, each testable on its own):

1. **Speech:** local streaming Whisper-class ASR with word confidence and a vineyard lexicon. Low confidence leads to a clarification question.
2. **Planner:** open-weight 7–14B instruct LLM, European models preferred, 4-bit QLoRA/VeRA.
   **Grammar-constrained decoding** produces a **typed mission DSL**. It calls tools (capabilities, pose, map,
   perception) instead of inventing state.
   Example: `navigate(row=3) -> survey(target="ripe cluster") -> report(...)`.
3. **Perception:** **SteerViT** (lab paper "Steerable Visual Representations", ECCV 2026 oral). Gated
   cross-attention on a frozen DINO-class ViT, so the mission phrase steers the features. About 21M trainable parameters.
   This is the **"V" in our VLA**.
4. **Grounding:** a topological row graph (row IDs, entry, exit, headland) over the occupancy map.
5. **Validation and execution:** a deterministic validator (types, preconditions, geofence, confidence, safety)
   compiles to ROS1. Uncertain or unsafe plans go to a human for approval. A runtime monitor handles replanning and safe stop.

**Proposal KPI targets:** intent ≥ 92 %, mission success ≥ 87 % in sim, paraphrase worst-case ≥ 87 %,
median latency ≤ 5 s (p95 ≤ 10 s), 100 % of plans validated, ≥ 95 % correct refusal of unsafe or out-of-scope requests.

**Proposal work plan:**

| Month | Planned work |
|-------|--------------|
| M1, Oct | Interfaces, ASR → DSL baseline, parser and compiler, missions run in sim |
| **M2, Nov (now)** | SteerViT adapted to clusters, rows and trunks. Row map. Paraphrase data. PEFT planner. Gate: held-out intent ≥ 90 %, valid ROS plans for all core scenarios |
| M3, Dec | Closed loop, safety, latency. **Mid-term:** ≥ 85 % sim mission success, median latency ≤ 5 s |
| M4, Jan | Physical robot integration |
| M5, Feb | Vineyard demo and final report |

**How 25 Nov maps onto VinePilot:** the three tasks are executed by the **DSL → validator → ROS1
compiler (orchestrator)** path. That is the core of module 5 and gives the proposal's "plan, not action"
story. A minimal LLM front-end produces the DSL from text for the one-pager. SteerViT, ASR and PEFT come after 25 Nov.

## 6. Timeline

| Date | Milestone |
|------|-----------|
| Mid-Oct 2026 | Kick-off and material release |
| **25 Nov 2026** | **Monthly evaluation: one-page report + JSON + photos + video** (see below) |
| Dec 2026 | Mid-term: assessment on the training environment |
| End Feb 2027 | Final event in Brussels (TBC) on a dedicated environment |

---

## 7. Deliverable due 25 Nov 2026 (monthly evaluation)

Send to the **challenge owner**, with the AI-BOOST coordinator in **CC**:

1. **One-page PDF**: a short solution description and results for the three tasks.
2. **Mapping JSON**. Score = (number of grapes in the JSON) / 270.
3. **Folder of monitoring pictures**. The grape's **simulator number must be clearly visible**
   in every picture, so the organizers can verify it.
4. **Task 3 video, about 1 min**, showing the spray on a specific ID. Graded pass / fail.

The submission is assembled in `submission/2026-11-25_monthly/`:

```
one_pager.pdf
mapping.json
monitoring_images/<id>.png      (one per mapped grape)
task3_spray_id<N>.mp4
```

**Status 24 Nov, 14:00: submission package ready** (details in each `results/*/NOTES.md`):

| Item | Result |
|------|--------|
| `mapping.json` | Laptop MAP run ([results](../results/20261124_0209_laptop_map/NOTES.md)): 246 entries, official 246/270 = 91.1 %; 230 distinct real grapes (85.2 %), 4 duplicates, 12 false positives. Cluster baseline: 226/270 |
| `monitoring_images/` | 246/246 NAV + APPROACH + photo ([results](../results/20261124_0414_laptop_task2/NOTES.md)). Grape number clearly readable in **226/246 images (91.9 %)**; **224 of the 230 mapped grapes (97.4 %)** correctly monitored; 224/270 = 83.0 % of all grapes. Misses: 12 false-positive entries, 8 row-end images (sign cut by the edge or overlapping its neighbour) |
| Task 3 video | `task3_spray_id355.mp4`, 67 s, entry 355 = sim grape 15, pass ([results](../results/20261124_0400_laptop_task3/NOTES.md)) |
| Report | `VinePilot_Monthly_Report_Nov2026.docx`: page 1 abstract + Tasks 1-3, appendices A-D (method, figures, discussion, further work) |

Heavy files are on the team Google Drive, not in git: the
[submission zip](https://drive.google.com/file/d/1kUJ31BFYslvEWClTrcahWCgMSXswEWh2/view) (mapping.json,
246 monitoring images, Task 3 video) and the full results folders with images and frames
([20261124_0209_laptop_map](https://drive.google.com/drive/folders/1C9vrCHq39BbJMth2TT7bNxle2KuSmQga),
[20261124_0414_laptop_task2](https://drive.google.com/drive/folders/1PIfYjUGBwE31Eadf6qX3J_yCBp0bPpYX),
[20261124_0400_laptop_task3](https://drive.google.com/drive/folders/17w0rzBce8TavdgED1d0SYfyBzHcv2HQB)).
The text files in those folders (NOTES, logs, metrics, sign checks) are also in git; git has the latest versions.

### Plan to hit 25 Nov

| Day | Work |
|-----|------|
| **Sun 22** | Get the materials onto anvme. Run the sim (Docker locally, or Apptainer on Alex). Run the stock MAP routine once and log it. |
| **Mon 23** | Mapping coverage: extend or adjust the waypoints so all 3 rows and both sides are covered, and tune the detector thresholds. Target ≫ 22/270. Write `orchestrator.py` (rospy) for NAV + APPROACH + image capture. |
| **Tue 24** | Run monitoring over all mapped IDs and capture images. Run Task 3 (spray on a randomizer ID) and record the 1-min video. Add a minimal NL to mission front-end (LLM → JSON plan → orchestrator) for the description. |
| **Wed 25** | Write the one-pager, package the submission and send it. |

### Open questions / risks

- **Where the sim runs.** On Alex there is no Docker, only Apptainer. The tarball can be converted
  with `apptainer build frasky.sif docker-archive://frasky_test.tar.gz`, but Gazebo then needs headless
  rendering (Xvfb) and screen recording for the video.
  - *Queue check, 22 Nov 05:xx:* full-GPU partitions report an estimated start of a100 **28 Nov**,
    a40 **30 Nov** and rtxpro6k **21 Dec**. All are after the deadline.
  - `a100mig` starts today, around 08:12, with 4 cores. However, MIG slices have no graphics
    (no OpenGL), so Gazebo's cameras fall back to CPU (Mesa) rendering, which is slow but workable.
    CUDA for YOLO still works on MIG.
  - **Plan:** use the **Mac** as the main box for the video and the interactive runs. Use
    `a100mig` + Apptainer as the batch fallback for mapping and monitoring.
- **Running on the Mac.** The Mac is an **M5 MacBook Air** (Apple Silicon), so the step-by-step guide in
  [MAC_SETUP.md](MAC_SETUP.md) applies. The image is linux/amd64.
  - *Apple Silicon:* Docker Desktop runs it under Rosetta/QEMU emulation, with no GPU, so Gazebo
    uses software rendering and runs slowly. Show the GUI with XQuartz (`DISPLAY=host.docker.internal:0`)
    or VNC. `start_sim.sh` will need small edits, because it assumes Linux X11 and possibly
    `--gpus`/`--net host`.
  - *Intel Mac:* runs natively, and is better.
  - On either, record the video with QuickTime screen recording.
  - **Status 23 Nov:** both work. Cluster job 5045806: 186 topics, all 7 routines, camera 30 Hz, RTF 0.52.
    Mac (VNC route, `start_sim_mac.sh vnc`): camera about 26–30 Hz, `/clock` running, all services up.
    The VNC view is laggy (CPU rendering + Rosetta + VNC), so record the video with ffmpeg inside the
    container, not through VNC.
  - **The grey camera frame is expected at spawn:** the robot starts at world (−7.5, 2.5) facing −x,
    away from the vineyard (grapes span world x −4.9…+5.0), and the world uses a grey background
    and ground.
- **The "simulator number" on grapes.** We need to confirm the Gazebo grape models show a visible
  label, and which camera view shows it. The robot camera after APPROACH is the likely choice.
- **Does `MAP` follow `husky_nav_out.json`?** If it does, full coverage means editing that file. Check
  inside the container.
- **Mapping duplicates.** One physical grape may get several IDs. Deduplicate by `grape_pose`
  distance before submitting, because the slides say "correctly identified *and located*".
