# Running the Frasky simulator on a Linux laptop

A Linux laptop is what the organizers designed for, so it is the best place to watch the robot and
record the Task 3 video. The image is **linux/amd64**: use an Intel/AMD-CPU laptop (not ARM).

The Mac files in `configs/mac/` are **not** the right choice here. Their XQuartz mode is macOS-only,
and their VNC mode renders on the CPU, which throws away the laptop's GPU.

## One-time setup

1. Install Docker Engine and the compose plugin (`docker compose version` must work), and add yourself
   to the `docker` group (log out and back in).
2. Unzip `ws_ai_boost-challenge_1.zip` (from the Drive folder), then:
   ```bash
   cd ws_ai_boost-challenge_1/Frasky_Vineyard_simulator
   docker load --input frasky_test.tar.gz
   mkdir -p captures my_pkgs
   ```
   Free disk needed: about 60 GB during setup.

## Start it (any GPU)

Keep this repo next to the simulator folder (`ws_ai_boost-challenge_1/VLA_AI_Pipeline` and
`ws_ai_boost-challenge_1/Frasky_Vineyard_simulator`), then from the repo:
```bash
source configs/linux/start_sim_linux.sh            # or: ... start_sim_linux.sh /path/to/Frasky_Vineyard_simulator
```
[`start_sim_linux.sh`](../configs/linux/start_sim_linux.sh) runs from the repo (nothing to copy, the
organizers' folder stays untouched) and picks the compose setup itself:

| Laptop GPU | What it uses | Gazebo / RViz | YOLO |
|---|---|---|---|
| **NVIDIA up to RTX 40** + Container Toolkit | organizers' `compose.yaml` | GPU | GPU |
| **NVIDIA RTX 50** (Blackwell) + Container Toolkit | `compose.yaml` + [`compose.nocuda.yaml`](../configs/linux/compose.nocuda.yaml) | GPU | CPU, ~0.3 s/frame |
| **Intel / AMD**, or NVIDIA without the toolkit | [`compose.nonvidia.yaml`](../configs/linux/compose.nonvidia.yaml) | Mesa / CPU | CPU |

NVIDIA laptops need the **NVIDIA Container Toolkit** once (asks for your sudo password):
```bash
bash configs/linux/install_nvidia_toolkit.sh
```
Without it, compose.yaml fails with `could not select device driver "nvidia" with capabilities: [[gpu]]`.
Check it with `docker run --rm --gpus all --entrypoint nvidia-smi frasky_test:latest`.

**RTX 50-series:** the image's PyTorch (2.4.1+cu121, Python 3.8) has CUDA kernels up to sm_90 only, and
torch builds for Blackwell (2.7+) no longer support Python 3.8. With CUDA visible, the YOLO node dies
on every frame with `CUDA error: no kernel image is available for execution on the device` and no
grapes get detected. `compose.nocuda.yaml` hides CUDA so YOLO runs on CPU; mapping works, just slower.

Then start the simulation. On an **Intel + NVIDIA laptop (hybrid graphics)**, do NOT use
`frasky_sim_start`. Run this from the repo on the host instead (leave the container shell open or exit it):
```bash
bash configs/linux/sim_up.sh              # add --rtf 0.12 for mapping with a CPU-only YOLO
bash configs/linux/sim_down.sh            # stop it; --reset-map also empties test_mapping.json
```
On a desktop where the NVIDIA card drives the screen, `frasky_sim_start` inside the container may work;
check the camera either way (below).

**Why: frozen robot camera.** With the image's default NVIDIA PRIME-offload GL settings on the real
display, the Gazebo window looks fine, but gzserver's robot camera kept publishing one stale frame for
a whole MAP run: 0 YOLO detections out of ~6,000 frames, grey ground only. Turning offload off breaks GL
entirely (`BadValue ... NV-GLX`, the Intel GPU drives the screen). Rendering gzserver into Xvfb with Mesa,
as the cluster job does, fixes it. [`sim_up.sh`](../configs/linux/sim_up.sh) does that and puts only the
Gazebo window (gzclient) on your screen. Mesa still runs at RTF ~0.97 on a 32-thread laptop CPU.

**Check the camera** while the robot moves (e.g. during MAP):
```bash
docker cp src/frasky_mission/camera_check.py frasky_test:/tmp/ && docker exec frasky_test bash -lc 'source /opt/ros/noetic/setup.bash && python3 /tmp/camera_check.py'
```
A working feed changes between frames and has vine/grape colours. Don't test with a single
`rostopic echo -n1`: the camera plugin pauses without subscribers and returns an old buffer.

**CPU-only YOLO (~0.2 s per frame): run MAP at `--rtf 0.12`, or the JSON stays EMPTY.** The crop
estimator pairs each YOLO detection with the depth cloud of the same timestamp (ApproximateTime sync,
short queue). The camera sends 30 frames per simulated second; if YOLO can't keep up, it works through a
backlog and its detections arrive ~0.4 s (sim) late. By then the matching cloud has left the queue, the
estimator never fires, and MAP finishes with `test_mapping.json = []` although YOLO saw thousands of
grapes. That is what happened at RTF 0.3 here (2,410 frames with grapes, 0 entries) and on the cluster's
CPU run (job 5058055). At 0.12 the camera gives ~3.6 frames per wall second, YOLO keeps up, and the lag
drops to ~0.03 s. Check it before starting MAP:
```bash
docker exec frasky_test bash -lc 'source /opt/ros/noetic/setup.bash && source ~/catkin_ws/devel/setup.bash && rostopic delay /robot_frasky/frasky_detection/crop_data'
```
Want < 0.1 s. MAP (450 s simulated) then takes ~65 min wall time. The JSON fills during the run, not
only at the end. With a GPU detector (cluster, Leonardo) none of this applies.

## Run the tasks (as done on 24 Nov)

Copy the scripts into the container once: `docker cp src/frasky_mission/. frasky_test:/tmp/mission/`.
Results of each run are in `results/` (see the NOTES.md in each folder).

| Task | Launch | Command (inside the container, in `/tmp/mission`) | Laptop time |
|---|---|---|---|
| 1 Mapping | `sim_up.sh --rtf 0.12`, then `mapping.launch` | `python3 routine.py HOMING MAP`, then stop the mapping nodes with SIGINT | 71 min |
| 2 Monitoring | `sim_up.sh`, then `navigation.launch` | `python3 -u mission.py --json test_mapping.json --action APPROACH --out /tmp/monitoring --all --rtf-nav 1.0 --rtf-act 0.3 --base-home` | 7.1 h (102 s per grape) |
| 3 Spray | as Task 2 | `python3 -u mission.py --json test_mapping.json --action SPRAY --out /tmp/spray --ids <id>` | ~4 min |

- `mission.py` publishes each entry's `robot_pose` on `/orchestrator/robot_pose`, calls NAV, then the
  action, and saves `<id>.png` (closest view + the view after the action, where the number signs are
  readable). Entries with an all-zero `robot_pose` get a pose derived from `grape_pose`. Use
  `python3 -u`, or `run.log` stays empty until the end (buffered output).
- It switches the sim speed with `gz physics -u`: full speed while driving, 0.3 during the action
  so the CPU detector keeps up. `--start N` skips the first N entries, to resume a run.
- `/tmp` inside the container is lost when the container is recreated: copy the output out
  (`docker cp frasky_test:/tmp/monitoring results/<run>/`) as soon as a run ends.
- Video: `record_topic.py` writes an image topic to MP4 at sim speed. For the Gazebo view, open a second
  gzclient on Xvfb :99 and make it follow the robot (`gz camera -c gzclient_camera1 -f frasky`), so a
  window on your screen can't cover it.

## Check it

Same four smoke-test commands as in [MAC_SETUP.md](MAC_SETUP.md#smoke-test-do-this-first-and-tell-me-the-output),
plus the speed:
```bash
docker exec frasky_test bash -lc 'source /opt/ros/noetic/setup.bash && timeout 5 gz stats -p'
```
The first column is the real-time factor. For comparison: cluster 0.52, Mac 0.03.

## If the window does not open

- `cannot open display`: run the `xhost` line again, and check `echo $DISPLAY` on the laptop.
  On Wayland desktops this still works through Xwayland.
- The `xhost +SI:localuser` rule only lets in a container user with the same UID as you. If your
  UID is not 1000 (`id -u`), use `xhost +local:` instead (any local user may then draw on your screen
  until you log out).
- NVIDIA: if Gazebo crashes with GLX errors, check `docker run --rm --gpus all ubuntu nvidia-smi` first.
- `MESA: warning: Driver does not support the 0xa788 PCI ID` / `failed to load driver: iris`: the
  laptop's Intel GPU is newer than the image's Mesa 21, so it falls back to llvmpipe (CPU). Harmless;
  use the NVIDIA GPU path above for speed.

## Log lines that look bad but are harmless

Seen on an RTX 5070 laptop with the simulator fully working (HOMING and mapping both run):
- `Spawn service failed. Exiting.`: a timeout race in `spawn_model`; the `frasky` model is in Gazebo
  (`rosservice call /gazebo/get_world_properties`) and the camera publishes at 30 Hz.
- `Parameter chain description not set` / `chains name not set`: the autonomous_task nodes keep running.
- `No p gain specified for pid ... wheel`, `TF_REPEATED_DATA`, `Couldn't open joystick /dev/input/js0`.
