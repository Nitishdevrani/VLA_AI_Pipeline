#!/usr/bin/env python3
"""Call Frasky routines in order and wait for each to finish.

A routine is finished when /robot_frasky/routine_status goes false -> true -> false
after the call. Runs inside the simulator container (system python3 + ROS env).

    python3 routine.py HOMING MAP --timeout 7200 --log /out/routines.jsonl
"""
import argparse
import json
import time

import rospy
from std_msgs.msg import Bool
from jntlb_fwk_msgs.srv import SetName

SERVICE = "/robot_frasky/Routine"
STATUS = "/robot_frasky/routine_status"


class StatusWatch:
    def __init__(self):
        self.value = None
        self.history = []  # (wall_time, sim_time, value) for every change
        rospy.Subscriber(STATUS, Bool, self._cb, queue_size=50)

    def _cb(self, msg):
        if msg.data != self.value:
            self.value = msg.data
            self.history.append((time.time(), rospy.get_time(), msg.data))


def run(name, watch, timeout, log):
    call = rospy.ServiceProxy(SERVICE, SetName)
    mark = len(watch.history)
    t0_wall, t0_sim = time.time(), rospy.get_time()
    rospy.loginfo("calling %s", name)
    call(name)
    seen_true = False
    result = "timeout"
    while not rospy.is_shutdown() and time.time() - t0_wall < timeout:
        changes = [v for (_, _, v) in watch.history[mark:]]
        if True in changes:
            seen_true = True
            after = changes[changes.index(True):]
            if False in after:
                result = "done"
                break
        time.sleep(0.5)
    rec = {
        "routine": name,
        "result": result,
        "saw_true": seen_true,
        "wall_s": round(time.time() - t0_wall, 1),
        "sim_s": round(rospy.get_time() - t0_sim, 1),
    }
    rospy.loginfo("%s", rec)
    if log:
        with open(log, "a") as f:
            f.write(json.dumps(rec) + "\n")
    return result == "done"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("routines", nargs="+")
    ap.add_argument("--timeout", type=float, default=3600, help="wall seconds per routine")
    ap.add_argument("--log", default="")
    a = ap.parse_args()
    rospy.init_node("mission_routine", anonymous=True)
    rospy.wait_for_service(SERVICE, timeout=120)
    watch = StatusWatch()
    time.sleep(2)  # let the status subscription connect
    for name in a.routines:
        if not run(name, watch, a.timeout, a.log):
            rospy.logerr("%s did not finish, stopping", name)
            raise SystemExit(1)


if __name__ == "__main__":
    main()
