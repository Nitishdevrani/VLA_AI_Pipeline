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

## Pick the compose file by GPU

Check with `lspci | grep -iE "vga|3d"`.

| Laptop GPU | Use | Extra setup |
|---|---|---|
| **NVIDIA** | organizers' `compose.yaml` + `start_sim.sh`, unchanged | NVIDIA driver + **NVIDIA Container Toolkit** (`nvidia-ctk runtime configure --runtime=docker`, restart docker) |
| **Intel / AMD** | our [`configs/linux/compose.nonvidia.yaml`](../configs/linux/compose.nonvidia.yaml) | none |

NVIDIA:
```bash
source start_sim.sh
```

Intel / AMD (copy `compose.nonvidia.yaml` into the simulator folder first):
```bash
xhost +SI:localuser:"$(id -un)"
docker compose -f compose.nonvidia.yaml up -d
docker compose -f compose.nonvidia.yaml exec frasky_test bash
```

Then, inside the container:
```bash
frasky_sim_start
```
Gazebo, RViz and rqt open as normal windows.

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
