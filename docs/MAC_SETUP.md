# Running the Frasky simulator on the MacBook Air (M5, Apple Silicon)

The organizers' `compose.yaml` targets an Ubuntu laptop with an NVIDIA GPU. On a Mac it fails as-is:
the NVIDIA device reservation, `/dev/dri`, and the NVIDIA GLX environment variables all break it.
We ship a Mac variant in [configs/mac/](../configs/mac/), which also lists every change and the reason for it.

## What to expect

- `frasky_test` is a **linux/amd64** image with ROS Noetic and Ubuntu 20.04. On the M5 it runs under **Rosetta**.
- There is no GPU passthrough, so Gazebo renders on the CPU (`LIBGL_ALWAYS_SOFTWARE=1`). The real-time factor will be
  below 1, which is fine for scripted missions.
- The MacBook Air has no fan and throttles on long runs. Keep it plugged in. Long batch runs can go to the cluster
  (see the bottom of this file).

## One-time setup

1. Install **Docker Desktop (Apple Silicon)**, then in Settings:
   - *General*: enable **"Use Rosetta for x86_64/amd64 emulation on Apple Silicon"**.
   - *Resources*: give it as many CPUs as possible, **≥ 12 GB RAM**, and **≥ 40 GB disk**. The image unpacks to
     about 25–30 GB.
2. Unzip `ws_ai_boost-challenge_1.zip` on the Mac.
3. Copy `compose.mac.yaml` and `start_sim_mac.sh` from this repo's `configs/mac/` into
   `ws_ai_boost-challenge_1/Frasky_Vineyard_simulator/`.
4. Load the image. This takes 10–20 minutes for 9 GB.
   ```bash
   cd ws_ai_boost-challenge_1/Frasky_Vineyard_simulator
   docker load --input frasky_test.tar.gz
   ```
5. For Plan A, install **XQuartz** (xquartz.org), log out and back in, then run once:
   ```bash
   defaults write org.xquartz.X11 nolisten_tcp -bool false
   defaults write org.xquartz.X11 enable_iglx -bool true
   ```
   Then quit and reopen XQuartz.

## Start the simulator

Plan A uses the Gazebo window through XQuartz:

```bash
source start_sim_mac.sh
```

Plan B uses a virtual display inside the container. Use it if Gazebo crashes with GLX errors or shows a black window.

```bash
source start_sim_mac.sh vnc
```

Then open Finder, choose **Go → Connect to Server**, and enter `vnc://localhost:5900`. The password is `frasky`.
The port is published on 127.0.0.1 only, so nobody else on your network can connect.

**Try Plan B first.** XQuartz only offers old OpenGL through indirect rendering, which Gazebo often draws black.
Plan B renders inside the container with Mesa, exactly like the working cluster run.

Both plans leave you in a shell inside the container. Run:

```bash
frasky_sim_start
```

To stop: run `frasky_sim_stop`, then `exit`, then `docker compose -f compose.mac.yaml down`.

## Smoke test (do this first and tell me the output)

In a second Mac terminal:

```bash
docker exec frasky_test bash -lc 'source /opt/ros/noetic/setup.bash && rostopic list | head -50'
docker exec frasky_test bash -lc 'source /opt/ros/noetic/setup.bash && rostopic hz /robot_frasky/camera/color/image_raw' # Ctrl-C after ~5 s
docker exec frasky_test bash -lc 'source /opt/ros/noetic/setup.bash && rosparam get /use_sim_time; rostopic echo -n1 /clock'
docker exec frasky_test bash -lc 'source /opt/ros/noetic/setup.bash && rosservice list | grep robot_frasky'
```

Also check the Gazebo window for the **grape number labels**. They have to be visible in the monitoring
photos.

## Files shared with the Mac

- `captures/` maps to `/captures` inside the container. Monitoring images and recorded bags land here.
- `test_mapping.json` is where the mapping output appears on the Mac after `MAP`. It starts as `[]`.
- `my_pkgs/` maps to `catkin_ws/src/my_pkgs`. Our orchestrator package goes here.

## Recording the Task 3 video (~1 min)

Use QuickTime: **File → New Screen Recording**, and record the Gazebo window or the Screen Sharing window. If emulation
makes the run slow, speed up the footage and say so in the caption. The task is graded pass/fail on the spray.

## Cluster fallback

The same image is being converted to `tools/containers/frasky_test.sif` on anvme so it can run headless on
the Alex `a100mig` partition (see [CHALLENGE.md](CHALLENGE.md), "Open questions / risks").
