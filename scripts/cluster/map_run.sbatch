#!/bin/bash -l
#SBATCH --job-name=frasky_map
#SBATCH --partition=a100mig
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --time=04:00:00
#SBATCH --output=/anvme/workspace/v115be23-ai_boost/experiments/%x_%j.log
#
# Task 1 (grape mapping) on Alex, headless: simulator + mapping.launch, then HOMING and MAP.
# Same container setup as sim_smoketest.sbatch (Xvfb + Mesa for Gazebo; --nv so YOLO uses the MIG GPU).
#
# Submit through scripts/cluster/submit_map.sh, which registers the run with new_experiment.sh
# and passes RUNDIR. Outputs in $RUNDIR/outputs:
#   crop_map_db/test_mapping.json   mapping result (what MAP writes)
#   routines.jsonl                  per-routine result and duration
#   frames/                         camera + detection images every 30 s
#   gzstats.log, *.log              speed and node logs
set -uo pipefail
source /home/hpc/v115be/v115be23/AI_Boost/scripts/env.sh
unset SLURM_EXPORT_ENV

SIF=$HEAVY/tools/containers/frasky_test.sif
SIMDIR=$HEAVY/sim/Frasky_Vineyard_simulator
OUT=${RUNDIR:-$EXP/map_${SLURM_JOB_ID}}/outputs
mkdir -p "$OUT/ros_home" "$OUT/frames" "$OUT/estimator_log"
CWS=/home/frasky_ws_container/catkin_ws/src
CMDB=$CWS/frasky_ws/frasky_detection/crop_map_db
echo "job $SLURM_JOB_ID on $(hostname), outputs in $OUT"

# own /etc/hosts (the image's is empty once site bind paths are off)
printf '127.0.0.1 localhost %s\n::1 localhost ip6-localhost\n' "$(hostname)" > "$OUT/hosts"

# writable copy of the map database folder, with the organizers' starting files
apptainer exec --no-mount home,bind-paths --no-home -B "$OUT":/out "$SIF" cp -r "$CMDB" /out/crop_map_db 2>&1 | grep -v WARNING
[ -d "$OUT/crop_map_db" ] || { echo "!!! could not copy crop_map_db out of the image"; exit 1; }
cp "$SIMDIR/test_mapping.json"     "$OUT/crop_map_db/test_mapping.json"      # starts as []
cp "$SIMDIR/mapping_first_row.json" "$OUT/crop_map_db/mapping_first_row.json"
touch "$OUT/.start_marker"

DNUM=$((90 + SLURM_JOB_ID % 50))
Xvfb :$DNUM -screen 0 1920x1080x24 -nolisten tcp >"$OUT/xvfb.log" 2>&1 &
XVFB_PID=$!
export DISPLAY=:$DNUM
sleep 3

APPT=(apptainer exec --nv --no-mount home,bind-paths --no-home --writable-tmpfs
  --env DISPLAY=$DISPLAY --env LIBGL_ALWAYS_SOFTWARE=1
  --env ROS_HOME=/out/ros_home --env ROS_LOG_DIR=/out/ros_home/log
  -B "$OUT":/out -B "$OUT/hosts":/etc/hosts
  -B "$OUT/crop_map_db":$CMDB
  -B "$OUT/estimator_log":/code/src/detection/frasky_detection/log
  -B "$SIMDIR/husky_nav_out.json":$CWS/frasky_ws/autonomous_task/robots/frasky/tasks/husky_nav_out.json
  -B "$SIMDIR/my_pkgs":$CWS/my_pkgs
  -B /home/hpc/v115be/v115be23/AI_Boost/src/frasky_mission:/mission
  "$SIF")
ROSENV='export HOME=/home/frasky_ws_container; source /opt/ros/noetic/setup.bash; source $HOME/catkin_ws/devel/setup.bash; source $HOME/catkin_ws/src/ros.env'
inapp() { "${APPT[@]}" bash -c "$ROSENV; $1"; }
# The image's ENV sets LD_LIBRARY_PATH and hides the --nv driver libs in /.singularity.d/libs.
# Tested in job 5058275: appending the folder still loads the wrong libcuda (CUDA unavailable), and
# prepending it breaks cv_bridge's import. Preloading only the host libcuda works, and only for the YOLO side.
GPUENV='export LD_PRELOAD=/.singularity.d/libs/libcuda.so.1'

echo "=== $(date) simulator"
inapp "roslaunch frasky_simulation frasky_simulation.launch gui:=false rviz:=false joystick:=false" >"$OUT/sim_roslaunch.log" 2>&1 &
SIM_PID=$!
up=0
for i in $(seq 1 60); do
  sleep 10
  kill -0 $SIM_PID 2>/dev/null || { echo "!!! simulator exited early"; break; }
  if inapp "rostopic list 2>/dev/null | grep -q /robot_frasky/camera/color/image_raw" 2>/dev/null; then
    echo "=== camera up after $((i*10)) s"; up=1; break; fi
done
[ $up = 1 ] || { kill $XVFB_PID; exit 1; }
sleep 60
inapp "$GPUENV; python3 -c 'import torch; print(\"torch cuda available:\", torch.cuda.is_available())'" 2>&1 | grep -v WARNING

( while kill -0 $SIM_PID 2>/dev/null; do inapp "timeout 5 gz stats -p 2>/dev/null | tail -1" 2>/dev/null | grep -v WARNING; sleep 60; done ) >"$OUT/gzstats.log" &
inapp "python3 /mission/frame_logger.py --out /out/frames --every 30 /robot_frasky/camera/color/image_raw /robot_frasky/detection_img" >"$OUT/frame_logger.log" 2>&1 &
LOGGER_PID=$!

echo "=== $(date) mapping.launch"
inapp "$GPUENV; roslaunch --screen frasky_detection mapping.launch" >"$OUT/mapping_launch.log" 2>&1 &
MAPL_PID=$!
sleep 90   # YOLO model load
if grep -q "Traceback" "$OUT/mapping_launch.log"; then
  echo "!!! mapping node crashed:"; grep -A8 Traceback "$OUT/mapping_launch.log" | head -20
  kill -INT $MAPL_PID $SIM_PID 2>/dev/null; sleep 10; kill $XVFB_PID 2>/dev/null; exit 1
fi

echo "=== $(date) HOMING + MAP"
inapp "python3 /mission/routine.py HOMING MAP --timeout 9000 --log /out/routines.jsonl" 2>&1 | grep -v WARNING > "$OUT/routine_run.log" &
RT_PID=$!
sleep 300   # diagnostics 5 min into MAP, while the robot drives
inapp "
  echo '--- estimator node';  rosnode info /robot_frasky/frasky_detection/crop_estimator_x_coord 2>&1
  echo '--- crop_map_db node'; rosnode info /robot_frasky/frasky_detection/crop_map_db 2>&1
  echo '--- detection params'; rosparam get /robot_frasky/frasky_detection 2>&1
  echo '--- crop_data rate';  timeout 20 rostopic hz /robot_frasky/frasky_detection/crop_data 2>&1 | tail -3
  echo '--- nodes'; rosnode list 2>&1 | grep -E 'frasky_detection|yolo'
  echo '--- crop_data sample'; timeout 15 rostopic echo -n2 /robot_frasky/frasky_detection/crop_data 2>&1 | head -60
  echo '--- detection_img rate'; timeout 15 rostopic hz /robot_frasky/detection_img 2>&1 | tail -2
  echo '--- estimator marker'; timeout 15 rostopic echo -n1 /robot_frasky/frasky_detection/visualization_marker 2>&1 | head -40
  echo '--- depth cloud rate'; timeout 20 rostopic hz /robot_frasky/camera/depth/color/points 2>&1 | tail -3
  echo '--- tf frames'; timeout 20 python3 -c \"
import rospy, tf2_ros
rospy.init_node('tfdump', anonymous=True); b = tf2_ros.Buffer(); tf2_ros.TransformListener(b); rospy.sleep(5)
print(b.all_frames_as_string())
for t in ['robot_frasky/C_1', 'robot_frasky/EE_3', 'robot_frasky/C_2']:
    print(t, 'world->' + t, b.can_transform('robot_frasky/world', t, rospy.Time(0)))
\" 2>&1
" > "$OUT/diag_5min.txt" 2>&1
echo "=== $(date) diagnostics written"; ls -la "$OUT/estimator_log"
wait $RT_PID
cat "$OUT/routine_run.log"
echo "=== $(date) routines finished"
cat "$OUT/routines.jsonl" 2>/dev/null

sleep 15
kill -INT $MAPL_PID 2>/dev/null; sleep 30; kill -9 $MAPL_PID 2>/dev/null
kill $LOGGER_PID 2>/dev/null

echo "=== map database files written during this run"
find "$OUT/crop_map_db" -newer "$OUT/.start_marker" -type f -exec ls -la {} \;
python3 - "$OUT/crop_map_db/test_mapping.json" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    print("test_mapping.json entries:", len(d))
except Exception as e:
    print("could not read test_mapping.json:", e)
PY

kill -INT $SIM_PID 2>/dev/null; sleep 15; kill -9 $SIM_PID 2>/dev/null
kill $XVFB_PID 2>/dev/null
echo "=== $(date) done"
