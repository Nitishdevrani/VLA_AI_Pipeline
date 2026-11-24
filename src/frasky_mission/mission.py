#!/usr/bin/env python3
"""Run Frasky missions from a mapping JSON: NAV to a grape, then APPROACH (Task 2) or SPRAY (Task 3).

For each selected entry:
  1. target = its robot_pose (map frame). Entries whose robot_pose is all zeros (the estimator
     sometimes leaves it empty) get a pose derived from grape_pose with FACE_POSE: same x, out in
     the corridor, heading along the row so the side camera (base -y) faces the grape.
  2. publish the target continuously on /orchestrator/robot_pose (frame_id "robot_pose"),
     call NAV and wait for routine_status false -> true -> false.
  3. call the action routine and wait. While it runs, keep camera frames; save the one taken
     when the end-effector was furthest from its start pose (the arm's closest look), plus the
     last frame, as <out>/<id>.png and <out>/frames/<id>_*.png.
One JSON line per grape goes to <out>/mission_log.jsonl.

Speed: the CPU YOLO needs a slow sim only while perception runs, so NAV runs at --rtf-nav and the
action at --rtf-act (set with `gz physics -u`). Run inside the simulator container with
navigation.launch already up:

    python3 mission.py --json test_mapping.json --action APPROACH --out /tmp/monitoring --all
    python3 mission.py --json test_mapping.json --action SPRAY --out /tmp/spray --ids 42
"""
import argparse
import json
import math
import os
import subprocess
import threading
import time

import cv2
import numpy as np
import rospy
from geometry_msgs.msg import PoseStamped
from sensor_msgs.msg import Image

from routine import StatusWatch, run as run_routine

POSE_TOPIC = "/orchestrator/robot_pose"
CAM_TOPIC = "/robot_frasky/camera/color/image_raw"
EE_TOPIC = "/robot_frasky/franka_ee_pose"
SLAM_TOPIC = "/auto2ark/ark_bridge/slam_estimated_pose_stamped"
# Row side (grape map y) -> (robot y offset from the grape, robot yaw), the medians of the valid
# robot_poses in the 24 Nov laptop MAP run. The camera looks along base -y, so the robot stands
# above the row facing +x, or below it facing -x.
FACE_POSE = {6.1: (0.97, 0.0), 4.9: (-0.68, math.pi), 3.1: (1.12, 0.0),
             1.9: (-0.72, math.pi), 0.1: (1.10, 0.0), -1.1: (-0.66, math.pi)}


def is_zero(d):
    return all(abs(v) < 1e-9 for v in d.values())


def target_pose(e):
    """(x, y, qz, qw, how) in the map frame for one mapping entry."""
    rp = e.get("robot_pose", {})
    p, q = rp.get("position", {}), rp.get("orientation", {})
    if p and not is_zero(p) and q and not is_zero(q):
        n = math.sqrt(sum(v * v for v in q.values()))
        return p["x"], p["y"], q["z"] / n, q["w"] / n, "robot_pose"
    g = e["grape_pose"]["position"]
    face = min(FACE_POSE, key=lambda f: abs(f - g["y"]))
    dy, yaw = FACE_POSE[face]
    return g["x"], g["y"] + dy, math.sin(yaw / 2), math.cos(yaw / 2), "from_grape_pose"


class PosePublisher:
    def __init__(self):
        self.pub = rospy.Publisher(POSE_TOPIC, PoseStamped, queue_size=1)
        self.msg = None
        self.lock = threading.Lock()
        rospy.Timer(rospy.Duration(0.05), self._tick)

    def set(self, x, y, qz, qw):
        m = PoseStamped()
        m.header.frame_id = "robot_pose"
        m.pose.position.x, m.pose.position.y = x, y
        m.pose.orientation.z, m.pose.orientation.w = qz, qw
        with self.lock:
            self.msg = m

    def _tick(self, _):
        with self.lock:
            if self.msg is not None:
                self.msg.header.stamp = rospy.Time.now()
                self.pub.publish(self.msg)


class FrameKeeper:
    """Keeps the latest camera frame; during an action, remembers the frame at max EE excursion."""

    def __init__(self):
        self.latest = None
        self.ee = None
        self.recording = False
        self.best = None
        self.best_d = -1.0
        self.start_ee = None
        self.n = 0
        rospy.Subscriber(CAM_TOPIC, Image, self._img, queue_size=1, buff_size=2 ** 24)
        rospy.Subscriber(EE_TOPIC, PoseStamped, self._ee, queue_size=1)

    def _img(self, m):
        a = np.frombuffer(m.data, np.uint8).reshape(m.height, m.width, -1)
        self.latest = a[..., ::-1].copy() if m.encoding.lower().startswith("rgb") else a.copy()
        if self.recording and self.ee is not None:
            self.n += 1
            if self.start_ee is None:
                self.start_ee = self.ee
            d = math.dist(self.ee, self.start_ee)
            if d > self.best_d:
                self.best_d, self.best = d, self.latest

    def _ee(self, m):
        p = m.pose.position
        self.ee = (p.x, p.y, p.z)


class RobotPose:
    """The base's estimated map pose, to log where the robot actually stopped."""

    def __init__(self):
        self.pose = None
        rospy.Subscriber(SLAM_TOPIC, PoseStamped, self._cb, queue_size=1)

    def _cb(self, m):
        p, q = m.pose.position, m.pose.orientation
        self.pose = (p.x, p.y, 2 * math.atan2(q.z, q.w))

    def get(self):
        if self.pose is None:
            return None
        x, y, yaw = self.pose
        yaw = math.degrees(math.atan2(math.sin(yaw), math.cos(yaw)))
        return [round(x, 3), round(y, 3), round(yaw, 1)]

    def start(self):
        self.best, self.best_d, self.start_ee, self.n = None, -1.0, None, 0
        self.recording = True

    def stop(self):
        self.recording = False
        return self.best, self.best_d, self.latest, self.n


def composite(close, home, entry_id, action):
    """Side by side: the arm's closest view, and the home-pose view where the number sign is readable."""
    h = max(close.shape[0], home.shape[0])
    pad = lambda im: cv2.copyMakeBorder(im, 0, h - im.shape[0], 0, 0, cv2.BORDER_CONSTANT)
    out = np.hstack([pad(close), np.full((h, 8, 3), 255, np.uint8), pad(home)])
    for x, text in [(8, "%s: closest view" % action), (close.shape[1] + 16, "after %s (sign view)" % action)]:
        cv2.putText(out, text, (x, h - 12), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 0), 3)
        cv2.putText(out, text, (x, h - 12), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 1)
    cv2.putText(out, "map entry %s" % entry_id, (8, 24), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 0), 3)
    cv2.putText(out, "map entry %s" % entry_id, (8, 24), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 1)
    return out


def set_rtf(rtf):
    if rtf:
        subprocess.run(["gz", "physics", "-u", str(int(round(rtf * 1000)))], check=False,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", required=True)
    ap.add_argument("--action", default="APPROACH", choices=["APPROACH", "SPRAY", "NONE"])
    ap.add_argument("--out", required=True)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--ids", type=int, nargs="+", help="entry ids from the JSON")
    g.add_argument("--all", action="store_true", help="every entry, in file order")
    ap.add_argument("--start", type=int, default=0, help="skip the first N selected entries (resume)")
    ap.add_argument("--max", type=int, default=0, help="stop after N entries (0 = no limit)")
    ap.add_argument("--rtf-nav", type=float, default=0.0, help="sim speed while driving (0 = unchanged)")
    ap.add_argument("--rtf-act", type=float, default=0.0, help="sim speed during the action")
    ap.add_argument("--timeout", type=float, default=900, help="wall seconds per routine")
    ap.add_argument("--base-home", action="store_true", help="call BASE_HOME at the end")
    a = ap.parse_args()

    entries = json.load(open(a.json))
    if a.ids:
        by_id = {e["id"]: e for e in entries}
        missing = [i for i in a.ids if i not in by_id]
        if missing:
            raise SystemExit("ids not in %s: %s" % (a.json, missing))
        sel = [by_id[i] for i in a.ids]
    else:
        sel = entries
    sel = sel[a.start:]
    if a.max:
        sel = sel[:a.max]
    os.makedirs(os.path.join(a.out, "frames"), exist_ok=True)
    log_path = os.path.join(a.out, "mission_log.jsonl")

    rospy.init_node("frasky_mission", anonymous=True)
    rospy.wait_for_service("/robot_frasky/Routine", timeout=120)
    watch = StatusWatch()
    poses = PosePublisher()
    frames = FrameKeeper()
    robot = RobotPose()
    time.sleep(2)

    for k, e in enumerate(sel):
        x, y, qz, qw, how = target_pose(e)
        rec = {"id": e["id"], "target": [round(x, 3), round(y, 3), round(qz, 4), round(qw, 4)], "target_from": how}
        t0 = time.time()
        rospy.loginfo("[%d/%d] id %s -> NAV to (%.2f, %.2f) [%s]", k + 1, len(sel), e["id"], x, y, how)
        poses.set(x, y, qz, qw)
        time.sleep(1.0)
        set_rtf(a.rtf_nav)
        t_nav = time.time()
        rec["nav"] = run_routine("NAV", watch, a.timeout, "")
        rec["nav_wall_s"] = round(time.time() - t_nav, 1)
        rec["pose_after_nav"] = robot.get()  # [x, y, yaw_deg] in the map frame
        if rec["nav"] and a.action != "NONE":
            set_rtf(a.rtf_act)
            time.sleep(1.0)
            frames.start()
            t_act, s_act = time.time(), rospy.get_time()
            rec["action"] = run_routine(a.action, watch, a.timeout, "")
            rec["action_wall_s"] = round(time.time() - t_act, 1)
            rec["action_sim_s"] = round(rospy.get_time() - s_act, 1)
            time.sleep(1.0)  # arm is back home: this frame shows the grape with its number sign
            best, best_d, last, n = frames.stop()
            rec["pose_at_photo"] = robot.get()
            rec["frames_seen"] = n
            rec["ee_excursion_m"] = round(best_d, 3)
            if best is not None:
                cv2.imwrite(os.path.join(a.out, "frames", "%s_closest.png" % e["id"]), best)
            if last is not None:
                cv2.imwrite(os.path.join(a.out, "frames", "%s_last.png" % e["id"]), last)
            if best is not None and last is not None:
                cv2.imwrite(os.path.join(a.out, "%s.png" % e["id"]), composite(best, last, e["id"], a.action))
        rec["wall_s"] = round(time.time() - t0, 1)
        with open(log_path, "a") as f:
            f.write(json.dumps(rec) + "\n")
        rospy.loginfo("%s", rec)
        if not rec["nav"]:
            rospy.logwarn("NAV failed for id %s, moving on", e["id"])

    if a.base_home:
        set_rtf(a.rtf_nav)
        run_routine("BASE_HOME", watch, a.timeout, "")


if __name__ == "__main__":
    main()
