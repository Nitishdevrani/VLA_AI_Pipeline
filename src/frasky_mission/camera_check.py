#!/usr/bin/env python3
"""Passive check that the robot camera renders the live scene (not one frozen frame).

Listens to the colour camera for a few seconds with ONE open subscription and reports:
  - frame rate,
  - how much the image changes over that time (0.00 for a frozen feed while the robot moves),
  - the share of vine/grape-coloured pixels (green or brown), so a grey-only image stands out.
Run inside the simulator container, ideally while the robot drives:

    python3 camera_check.py [--seconds 10] [--save /tmp/camera_check.jpg]

Why this exists (24 Nov, Intel+NVIDIA laptop): with gzserver rendering through NVIDIA PRIME
offload on the real X display, the camera published the same stale frame for a whole MAP run
(0 YOLO detections) while the Gazebo window looked fine. Rendering gzserver into Xvfb with Mesa
fixed it. Two traps when checking by hand:
  - The openni camera plugin pauses the sensor when nobody subscribes, so a one-off
    `rostopic echo -n1` / wait_for_message can return an old buffer. Keep a subscription open.
  - Models spawned after start did not show up in the camera, so a "spawn a box" test fails
    even when the camera works. Look at the vineyard instead.
"""
import argparse
import time

import cv2
import numpy as np
import rospy
from sensor_msgs.msg import Image

TOPIC = "/robot_frasky/camera/color/image_raw"


def to_bgr(m):
    a = np.frombuffer(m.data, np.uint8).reshape(m.height, m.width, -1).copy()
    return a[..., ::-1] if m.encoding.lower().startswith("rgb") else a


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seconds", type=float, default=10.0)
    ap.add_argument("--save", default="")
    a = ap.parse_args()
    rospy.init_node("camera_check", anonymous=True)

    frames = []

    def cb(m):
        frames.append(to_bgr(m))
        if len(frames) > 2:
            del frames[1:-1]  # keep first and latest only

    count = {"n": 0}

    def counting_cb(m):
        count["n"] += 1
        cb(m)

    rospy.Subscriber(TOPIC, Image, counting_cb, queue_size=1, buff_size=2 ** 24)
    rospy.sleep(2.0)  # let the plugin wake the sensor up
    count["n"] = 0
    frames.clear()
    t0 = time.time()
    rospy.sleep(a.seconds)
    wall = time.time() - t0
    if len(frames) < 2:
        print("no images on %s" % TOPIC)
        raise SystemExit(1)

    first, last = frames[0], frames[-1]
    change = float(np.abs(first.astype(int) - last.astype(int)).mean())
    b, g, r = [last[..., i].astype(int) for i in range(3)]
    green = (g > r + 15) & (g > b + 15)
    brown = (r > b + 30) & (r > g)
    plant = 100.0 * float((green | brown).mean())
    sat = float(cv2.cvtColor(last, cv2.COLOR_BGR2HSV)[..., 1].mean())
    if a.save:
        cv2.imwrite(a.save, last)

    print("frames: %d in %.1f s wall (%.1f fps)" % (count["n"], wall, count["n"] / wall))
    print("image change first->last: %.2f  (0.00 while the robot moves = frozen feed)" % change)
    print("vine/grape-coloured pixels: %.1f %%   mean saturation: %.0f  (grey-only image ~0)" % (plant, sat))


if __name__ == "__main__":
    main()
