# 20261124_0400_laptop_task3

- Description: Task 3 (precision treatment) on the Linux laptop. Grape picked with the organizers'
  randomiser from the laptop MAP JSON (`../20261124_0209_laptop_map/test_mapping.json`): **entry 355**,
  which is sim grape 15 (estimated grape_pose 5.2 cm from ground truth, evaluation only).
- Setup: `configs/linux/sim_up.sh`, `navigation.launch`, then
  `src/frasky_mission/mission.py --action SPRAY --ids 355`: publish the entry's robot_pose as the goal,
  NAV, SPRAY (homing + frasky_spray_fake + homing). YOLO on CPU.
- Result: **pass.** NAV succeeded (112 s wall), SPRAY succeeded (96 s wall / 27.6 s sim), arm moved
  0.60 m. `355.png`: nozzle view during the spray (left) and the view after it, with signs 12-18 and
  grape 15 centred (right). `mission_log.jsonl`: the run record.
- Video: `submission/2026-11-25_monthly/task3_spray_id355.mp4` (67 s, sim speed): Gazebo view
  following the robot, recorded from a second gzclient on Xvfb :99, with the robot camera inset
  (`src/frasky_mission/record_topic.py`). The video is in the submission zip on the team Google Drive,
  not in git.
