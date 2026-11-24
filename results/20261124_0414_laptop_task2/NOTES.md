# 20261124_0414_laptop_task2

- Description: Task 2 monitoring on the Linux laptop. For every entry of the laptop MAP JSON
  (`../20261124_0209_laptop_map/test_mapping.json`, 246 entries): publish a goal pose, NAV, APPROACH,
  save a photo. Driven by `src/frasky_mission/mission.py --action APPROACH --all`; NAV, path planning
  and the arm motion are the organizers' routines. YOLO on CPU (navigation.launch).
- Ran: 2026-11-24 04:14 to 11:20 (7.1 h wall).
- Files: `<id>.png` (one per entry: arm's largest-excursion frame + frame after APPROACH, where the
  number signs are readable), `frames/<id>_closest.png` and `frames/<id>_last.png`,
  `mission_log.jsonl` (one line per entry), `sample_entry3.png` (early sample).
  The images and frames (217 MB) are not in git: they are on the team Google Drive in
  [20261124_0414_laptop_task2](https://drive.google.com/drive/folders/1PIfYjUGBwE31Eadf6qX3J_yCBp0bPpYX)
  (the Drive copy of this NOTES.md is an older version; this one is current).
- Result: 246/246 NAV succeeded, 246/246 APPROACH succeeded, 246/246 photos.
  Goal poses: 217 from the entry's robot_pose, 29 derived from grape_pose (robot_pose was all zeros).
  Per entry: NAV median 4.5 s wall (max 62 s), APPROACH median 93 s wall / 27.7 s sim, total median 102 s.
  Arm moved 0.32-0.65 m from its start pose in every APPROACH.
- Photo check (HSV grape/leaf pixel share >= 10 % in either frame): 245/246. The exception is entry 198
  (robot at the end of row side 91-135, grapes only in the distance).
- Right grape in the photo? (evaluation only, `src/eval/score_mapping.py` matching against the sim
  ground truth): 234 entries match a sim grape (230 distinct + 4 duplicates, same as Task 1). For all
  234 the matched grape is 0.01-0.37 m along the row from the robot's stop pose, so it is always in
  the camera's horizontal field of view (the sign view spans about 6 signs, +-0.6 m).
- **Sign check, all 246 photos (final, `sign_check_v2.json`).** Each after-APPROACH frame
  (`frames/<id>_last.png`) was cropped to its sign band, labelled with the expected sim number and
  checked by eye: **226 readable, 8 partly visible, 12 not a real grape.**
  `sign_check_v1.json` (12:10, 127 readable / 107 "sign cut off") is superseded: 99 of its 107
  "cut off" photos show the expected number in full, near the top edge of the image. v2 keeps the
  v1 verdict per entry as `v1_verdict`.

  | Row side (sim IDs) | 1-45 | 46-90 | 91-135 | 136-180 | 181-225 | 226-270 |
  |---|---|---|---|---|---|---|
  | robot heading | +x | -x | +x | -x | +x | -x |
  | stored standoff from the row (m) | 0.97 | 0.68 | 1.12 | 0.72 | 1.10 | 0.66 |
  | number clearly readable / matched entries | 44/44 | 42/44 | 24/24 | 43/45 | 31/31 | 42/46 |
  | number partly visible | 0 | 2 | 0 | 2 | 0 | 4 |

  Partly visible (all at row ends): 399, 400 (sims 90, 89: sign cut by the top edge); 277, 278
  (sims 180, 179) and 155, 149, 151, 154 (sims 269, 270): neighbouring signs overlap in the world.
  Scores: per entry 226/246 = 91.9 % (challenge metric); per grape found in mapping 224/230 =
  97.4 % (230/230 at least partly); of all 270 grapes 224 = 83.0 % (230 = 85.2 %). Sims 40 and 154
  each have two readable entries, so 226 images cover 224 grapes.
  On the -x sides (standoff ~0.7 m) the signs sit near the top edge, so there is little margin; the
  "closest view" frame (max end-effector excursion) there usually looks away from the row, so the
  right half of each `<id>.png` is the useful one.
- Tried and dropped (24 Nov, 12:15-12:45): standing 0.9 m back on the -x sides. In the inner corridor
  (goal y 4.02 for side 46-90) move_base aborted ("Failed to find a valid control"), the base ended up
  turned 49 deg in the costmap's obstacle zone, and every later NAV returned "done" without moving.
  Next fix to try: pick the photo during APPROACH, or an arm pose that frames the sign.
- The 12 unmatched entries (1, 139, 144-148, 150, 153, 198, 327, 398) are mapping false positives at
  the row ends (map x ~ -2.4 or -12.0 to -12.7). Their photos show the nearest real grapes (signs 1-3,
  91-93, 181-185, 268-270) or, for 139/144-147 (five entries at one spot), a close-up with the signs
  cut off. Dropping these from the map would leave 234 entries.
