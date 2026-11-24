#!/usr/bin/env bash
# Stop everything sim_up.sh and the mission scripts started inside frasky_test (the container keeps running).
#
#   bash configs/linux/sim_down.sh [--reset-map]
#
# --reset-map also empties the map database file (test_mapping.json, bind-mounted from the
# simulator folder) and the crop estimator logs, so the next MAP run starts from nothing.
# Copy any result you want to keep out first.
set -uo pipefail
C=frasky_test
# Patterns use [x]yz so pkill never matches the shell running this command.
docker exec "$C" bash -c 'pkill -INT -f "[r]oslaunch" ; sleep 8
  pkill -9 -f "[g]zserver|[g]zclient|[r]osmaster|[r]oslaunch|[f]rame_logger.py|[r]outine.py|[g]z stats" ; sleep 2
  pgrep -fa "[g]zserver|[r]osmaster" && echo "!!! some processes are still running" || echo ">>> simulation stopped"'
if [ "${1:-}" = "--reset-map" ]; then
    docker exec "$C" bash -c 'echo "[]" > ~/catkin_ws/src/frasky_ws/frasky_detection/crop_map_db/test_mapping.json
      rm -f /code/src/detection/frasky_detection/log/*.txt 2>/dev/null; echo ">>> map database emptied"'
fi
