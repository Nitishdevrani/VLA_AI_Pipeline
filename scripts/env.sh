# Source this in every shell / job script:   source ~/AI_Boost/scripts/env.sh
# Points every cache and heavy-output location at the anvme workspace,
# so nothing large lands in $HOME (which is close to its quota).

export PROJ=/home/hpc/v115be/v115be23/AI_Boost
export HEAVY=$(ws_find -F anvme ai_boost 2>/dev/null || echo /anvme/workspace/v115be23-ai_boost)

if [ ! -d "$HEAVY" ]; then
  echo "[env.sh] WARNING: anvme workspace 'ai_boost' not found (expired?). Run: ws_list" >&2
fi

# Python / ML caches
export PIP_CACHE_DIR=$HEAVY/cache/pip
export HF_HOME=$HEAVY/cache/hf
export TORCH_HOME=$HEAVY/cache/torch
export CONDA_PKGS_DIRS=$HEAVY/cache/conda_pkgs
export XDG_CACHE_HOME=$HEAVY/cache

# Containers (Apptainer images for ROS/Gazebo live in tools/containers)
export APPTAINER_CACHEDIR=$HEAVY/cache/apptainer
export APPTAINER_TMPDIR=$HEAVY/cache/tmp

# ROS / Gazebo
export ROS_LOG_DIR=$HEAVY/cache/ros_logs
export ROS_HOME=$HEAVY/cache/ros_home
export GAZEBO_MODEL_PATH=$HEAVY/sim/models${GAZEBO_MODEL_PATH:+:$GAZEBO_MODEL_PATH}
export GZ_SIM_RESOURCE_PATH=$HEAVY/sim/models:$HEAVY/sim/worlds${GZ_SIM_RESOURCE_PATH:+:$GZ_SIM_RESOURCE_PATH}

# Convenience paths
export DATA=$HEAVY/data
export ROS_WS=$HEAVY/ros_ws
export EXP=$HEAVY/experiments
export CKPT=$HEAVY/checkpoints

mkdir -p "$ROS_HOME" 2>/dev/null
