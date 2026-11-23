#!/bin/bash -l
#SBATCH --job-name=frasky_smoke
#SBATCH --partition=a100mig
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --time=01:00:00
#SBATCH --output=/anvme/workspace/v115be23-ai_boost/experiments/%x_%j.log
#
# Headless smoke test of the Frasky simulator on Alex.
#   - Xvfb on the node provides a display; Gazebo renders cameras with Mesa (CPU),
#     since MIG slices expose no graphics.
#   - The simulator runs from the read-only SIF with --writable-tmpfs for scratch writes.
# Submit:  sbatch scripts/cluster/sim_smoketest.sbatch
set -uo pipefail
source /home/hpc/v115be/v115be23/AI_Boost/scripts/env.sh
unset SLURM_EXPORT_ENV

SIF=$HEAVY/tools/containers/frasky_test.sif
SIMDIR=$HEAVY/sim/Frasky_Vineyard_simulator
OUT=$EXP/smoke_${SLURM_JOB_ID}
mkdir -p "$OUT" "$OUT/ros_home"
CWS=/home/frasky_ws_container/catkin_ws/src
cp "$SIMDIR/test_mapping.json" "$OUT/test_mapping.json"   # writable copy, MAP writes here
# --no-mount bind-paths also drops the site /etc/hosts bind, and the image's own /etc/hosts is empty,
# so roslaunch cannot resolve "localhost". Give the container its own hosts file.
printf '127.0.0.1 localhost %s\n::1 localhost ip6-localhost\n' "$(hostname)" > "$OUT/hosts"

# --- virtual display on the node
DNUM=$((90 + SLURM_JOB_ID % 50))
Xvfb :$DNUM -screen 0 1920x1080x24 -nolisten tcp >"$OUT/xvfb.log" 2>&1 &
XVFB_PID=$!
export DISPLAY=:$DNUM
sleep 3

APPT=(apptainer exec --no-mount home,bind-paths --no-home --writable-tmpfs
  --env DISPLAY=$DISPLAY
  --env LIBGL_ALWAYS_SOFTWARE=1 --env ROS_HOME=/out/ros_home --env ROS_LOG_DIR=/out/ros_home/log
  -B "$OUT":/out -B "$OUT/hosts":/etc/hosts
  -B "$OUT/test_mapping.json":$CWS/frasky_ws/frasky_detection/crop_map_db/test_mapping.json
  -B "$SIMDIR/mapping_first_row.json":$CWS/frasky_ws/frasky_detection/crop_map_db/mapping_first_row.json
  -B "$SIMDIR/husky_nav_out.json":$CWS/frasky_ws/autonomous_task/robots/frasky/tasks/husky_nav_out.json
  -B "$SIMDIR/my_pkgs":$CWS/my_pkgs
  "$SIF")
ROSENV='export HOME=/home/frasky_ws_container; source /opt/ros/noetic/setup.bash; source /home/frasky_ws_container/catkin_ws/devel/setup.bash; source /home/frasky_ws_container/catkin_ws/src/ros.env'

echo "=== $(date) starting simulator (gui:=false rviz:=false joystick:=false) on $(hostname)"
"${APPT[@]}" bash -c "$ROSENV; roslaunch frasky_simulation frasky_simulation.launch gui:=false rviz:=false joystick:=false" \
   >"$OUT/sim_roslaunch.log" 2>&1 &
SIM_PID=$!

# --- wait for the camera topic (up to 10 min)
for i in $(seq 1 60); do
  sleep 10
  if ! kill -0 $SIM_PID 2>/dev/null; then echo "=== simulator exited early, see sim_roslaunch.log"; break; fi
  if "${APPT[@]}" bash -c "$ROSENV; rostopic list 2>/dev/null | grep -q /robot_frasky/camera/color/image_raw"; then
    echo "=== camera topic up after $((i*10)) s"; break; fi
done
sleep 30

"${APPT[@]}" bash -c "$ROSENV
  echo '--- topics';   rostopic list | sort | tee /out/topics.txt | wc -l
  echo '--- services'; rosservice list | grep robot_frasky | tee /out/services.txt
  echo '--- routine params'; rosparam list | grep -E '^/robot_frasky/(MAP|NAV|APPROACH|SPRAY|HOMING|BASE_HOME|GRASP)\$'
  echo '--- camera rate';  timeout 15 rostopic hz /robot_frasky/camera/color/image_raw 2>&1 | tail -3
  echo '--- sim speed';    timeout 10 gz stats -p 2>/dev/null | tail -3
  echo '--- robot_state';  timeout 5 rostopic echo -n1 /auto2ark/robot_state
  echo '--- save camera frame'
  cd /out && timeout 30 python3 - <<'PY'
import rospy, numpy as np
from sensor_msgs.msg import Image
rospy.init_node('grab', anonymous=True)
m = rospy.wait_for_message('/robot_frasky/camera/color/image_raw', Image, timeout=20)
a = np.frombuffer(m.data, np.uint8).reshape(m.height, m.width, -1)
if m.encoding.lower().startswith('rgb'): a = a[..., ::-1]
import cv2; cv2.imwrite('/out/camera_frame.png', a); print('saved', a.shape, m.encoding)
PY
" 2>&1 | tee "$OUT/smoke_summary.txt"

echo "=== $(date) shutting down"
kill -INT $SIM_PID 2>/dev/null; sleep 15; kill -9 $SIM_PID 2>/dev/null
kill $XVFB_PID 2>/dev/null
echo "=== done, outputs in $OUT"
