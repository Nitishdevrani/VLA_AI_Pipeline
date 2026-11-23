#!/usr/bin/env bash
# Mac launcher for the Frasky simulator.   Usage (from the Frasky_Vineyard_simulator folder):
#   source start_sim_mac.sh          # Plan A: Gazebo window via XQuartz
#   source start_sim_mac.sh vnc      # Plan B: virtual display in container, view at vnc://localhost:5900
mkdir -p captures my_pkgs

if [ "${1:-}" = "vnc" ]; then
  export FRASKY_DISPLAY=":1" FRASKY_INDIRECT=0
else
  export FRASKY_DISPLAY="host.docker.internal:0" FRASKY_INDIRECT=1
  open -a XQuartz
  sleep 2
  /opt/X11/bin/xhost + 127.0.0.1 >/dev/null
  /opt/X11/bin/xhost + localhost >/dev/null
fi

docker compose -f compose.mac.yaml up -d

if [ "${1:-}" = "vnc" ]; then
  # the image runs as a normal user, so installing needs root; the display tools then run as that user
  docker exec -u root frasky_test bash -c '
    command -v Xvfb >/dev/null && command -v x11vnc >/dev/null && command -v fluxbox >/dev/null ||
      (echo ">>> installing xvfb, x11vnc, fluxbox (first start only, ~1 min)";
       apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq xvfb x11vnc fluxbox >/dev/null)
  ' || { echo "!!! install failed, see output above"; return 1 2>/dev/null || exit 1; }
  docker exec frasky_test bash -lc '
    pgrep Xvfb   >/dev/null || (Xvfb :1 -screen 0 1920x1080x24 >/tmp/xvfb.log 2>&1 &)
    sleep 1
    pgrep fluxbox >/dev/null || (DISPLAY=:1 fluxbox >/tmp/fluxbox.log 2>&1 &)
    pgrep x11vnc  >/dev/null || (x11vnc -display :1 -forever -passwd frasky -shared -rfbport 5900 >/tmp/x11vnc.log 2>&1 &)
  '
  echo ">>> Open Finder -> Go -> Connect to Server -> vnc://localhost:5900  (password: frasky)"
fi

docker compose -f compose.mac.yaml exec frasky_test bash
