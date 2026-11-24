#!/usr/bin/env bash
# Linux laptop launcher for the Frasky simulator. Runs straight from this repo; nothing to copy.
#
#   source configs/linux/start_sim_linux.sh [SIM_DIR]
#
# SIM_DIR is the organizers' Frasky_Vineyard_simulator folder (holds the JSON files and my_pkgs).
# Default: the current folder if it has the organizers' compose.yaml, else ../Frasky_Vineyard_simulator
# next to this repo.
#
# Picks the compose setup by what the laptop has:
#   NVIDIA + Container Toolkit, GPU up to RTX 40   -> organizers' compose.yaml (GPU for Gazebo and YOLO)
#   NVIDIA + Container Toolkit, RTX 50 (Blackwell) -> + compose.nocuda.yaml (GPU for Gazebo, YOLO on CPU)
#   no NVIDIA Container Toolkit                     -> compose.nonvidia.yaml (Mesa / CPU rendering)

_FRASKY_LINUX_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
_FRASKY_REPO="$(cd -- "$_FRASKY_LINUX_DIR/../.." && pwd)"

if [ -n "${1:-}" ]; then
    FRASKY_SIM_DIR="$(cd -- "$1" && pwd)"
elif [ -f "./compose.yaml" ] && grep -q "frasky_test" ./compose.yaml; then
    FRASKY_SIM_DIR="$(pwd)"
else
    FRASKY_SIM_DIR="$(cd -- "$_FRASKY_REPO/../Frasky_Vineyard_simulator" 2>/dev/null && pwd)"
fi

if [ -z "$FRASKY_SIM_DIR" ] || [ ! -f "$FRASKY_SIM_DIR/compose.yaml" ]; then
    echo "!!! Frasky_Vineyard_simulator folder not found. Pass it: source $_FRASKY_LINUX_DIR/start_sim_linux.sh /path/to/Frasky_Vineyard_simulator"
    return 1 2>/dev/null || exit 1
fi
echo ">>> simulator folder: $FRASKY_SIM_DIR"
mkdir -p "$FRASKY_SIM_DIR/captures" "$FRASKY_SIM_DIR/my_pkgs"

# Let the container user (same UID as you) draw on your display.
xhost +SI:localuser:"$(id -un)" >/dev/null

if docker info 2>/dev/null | grep -qi 'runtimes:.*nvidia'; then
    FRASKY_COMPOSE=(-f "$FRASKY_SIM_DIR/compose.yaml")
    # The image's PyTorch (2.4.1+cu121, Python 3.8) has CUDA kernels only up to sm_90.
    # RTX 50-series (compute capability 12.x) makes YOLO crash with "no kernel image is available".
    _cc_major="$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null | head -1 | cut -d. -f1)"
    if [ -n "$_cc_major" ] && [ "$_cc_major" -ge 10 ]; then
        echo ">>> GPU compute capability ${_cc_major}.x: Gazebo/RViz on GPU, YOLO on CPU (see docs/LINUX_SETUP.md)"
        FRASKY_COMPOSE+=(-f "$_FRASKY_LINUX_DIR/compose.nocuda.yaml")
    else
        echo ">>> NVIDIA GPU: organizers' compose.yaml"
    fi
else
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo ">>> NVIDIA GPU found but Docker has no NVIDIA runtime. Install it once with:"
        echo "      bash $_FRASKY_LINUX_DIR/install_nvidia_toolkit.sh"
        echo "    Starting without the NVIDIA GPU for now (slow rendering)."
    else
        echo ">>> No NVIDIA GPU: compose.nonvidia.yaml"
    fi
    FRASKY_COMPOSE=(-f "$_FRASKY_LINUX_DIR/compose.nonvidia.yaml")
fi

# --project-directory keeps the ./*.json and ./my_pkgs mounts pointing at the simulator folder.
FRASKY_COMPOSE=(--project-directory "$FRASKY_SIM_DIR" "${FRASKY_COMPOSE[@]}")
export FRASKY_COMPOSE

docker compose "${FRASKY_COMPOSE[@]}" up -d
docker compose "${FRASKY_COMPOSE[@]}" exec frasky_test bash
