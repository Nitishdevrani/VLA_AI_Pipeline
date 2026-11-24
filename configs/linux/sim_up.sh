#!/usr/bin/env bash
# Start the Frasky simulation inside the running frasky_test container so the robot camera works.
#
#   bash configs/linux/sim_up.sh [--no-gui] [--rtf 0.12]
#
# --rtf: with YOLO on CPU (~0.2 s/frame) use 0.1-0.12 for mapping. Faster, and YOLO falls behind
# the 30 Hz camera; its detections then arrive ~0.4 s (sim) late, the crop estimator can't pair
# them with a depth cloud, and MAP ends with an EMPTY test_mapping.json. Check before MAP with
#   rostopic delay /robot_frasky/frasky_detection/crop_data      (want < 0.1 s)
#
# Run it after the container is up (start_sim_linux.sh, or docker compose up -d), INSTEAD of
# frasky_sim_start. It:
#   1. installs Xvfb in the container if missing (lost when the container is recreated),
#   2. runs gzserver/ROS on a virtual display :99 with Mesa (CPU) rendering,
#   3. opens the Gazebo window (gzclient) on your real screen, unless --no-gui,
#   4. optionally slows the sim (--rtf), so a CPU-only YOLO sees more frames per metre.
#
# Why: on an Intel+NVIDIA laptop (NVIDIA PRIME offload), gzserver's camera published one stale
# frame for a whole MAP run -> 0 detections, although the Gazebo window looked fine. The cluster
# setup (Xvfb + Mesa) works, so this script copies it. Check with src/frasky_mission/camera_check.py.
set -euo pipefail
GUI=1
RTF=""
while [ $# -gt 0 ]; do
    case "$1" in
        --no-gui) GUI=0 ;;
        --rtf) RTF="$2"; shift ;;
        *) echo "unknown option $1"; exit 1 ;;
    esac
    shift
done

C=frasky_test
docker ps --format '{{.Names}}' | grep -qx "$C" || { echo "!!! container $C is not running; start it first"; exit 1; }

MODELS='$ROS_WS/src/frasky_ws/frasky_simulation/worlds/vine_models:$ROS_WS/src/frasky_ws/frasky_simulation/worlds/output_with_grapes_grape_materials:$GAZEBO_MODEL_PATH'

if ! docker exec "$C" bash -c 'command -v Xvfb >/dev/null'; then
    echo ">>> installing Xvfb in the container (first start only, ~1 min)"
    docker exec -u root "$C" bash -c 'apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq xvfb >/dev/null'
fi
docker exec "$C" bash -c 'pgrep -x Xvfb >/dev/null || (Xvfb :99 -screen 0 1920x1080x24 -nolisten tcp >/tmp/xvfb.log 2>&1 &)'
# The crop estimator writes its per-run log here (hard-coded path); it does not exist in the image.
docker exec -u root "$C" bash -c 'mkdir -p /code/src/detection/frasky_detection/log && chown -R 1000:1000 /code'

if docker exec "$C" bash -c 'pgrep -x gzserver >/dev/null'; then
    echo ">>> gzserver already running; stop it first (frasky_sim_stop, or restart the container)"
    exit 1
fi

echo ">>> starting simulation on Xvfb :99 (log: /tmp/frasky_sim.log in the container)"
docker exec -d "$C" bash -ic "export DISPLAY=:99 __GLX_VENDOR_LIBRARY_NAME=mesa __NV_PRIME_RENDER_OFFLOAD=0 LIBGL_ALWAYS_SOFTWARE=1 GAZEBO_MODEL_PATH=$MODELS; roslaunch frasky_simulation frasky_simulation.launch gui:=false rviz:=false joystick:=false > /tmp/frasky_sim.log 2>&1"

for i in $(seq 1 60); do
    sleep 5
    if docker exec "$C" bash -c 'source /opt/ros/noetic/setup.bash; rosservice list 2>/dev/null | grep -q /robot_frasky/Routine'; then
        echo ">>> simulation up after $((i * 5)) s"
        break
    fi
    [ "$i" = 60 ] && { echo "!!! simulation did not come up, see /tmp/frasky_sim.log"; exit 1; }
done

if [ "$GUI" = 1 ]; then
    # The window runs on the real display with the image's normal (NVIDIA offload) GL settings.
    docker exec -d "$C" bash -ic "export GAZEBO_MODEL_PATH=$MODELS; gzclient > /tmp/gzclient.log 2>&1"
    echo ">>> Gazebo window opening on your screen"
fi

if [ -n "$RTF" ]; then
    sleep 10
    rate=$(python3 -c "print(int(round(float('$RTF') * 1000)))")   # max_step_size is 0.001 s
    docker exec "$C" bash -c "source /opt/ros/noetic/setup.bash; gz physics -u $rate"
    echo ">>> real-time factor target set to $RTF"
fi
