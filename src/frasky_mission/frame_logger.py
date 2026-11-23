#!/usr/bin/env python3
"""Save one image every N wall seconds from each given topic (diagnostics during long runs).

    python3 frame_logger.py --out /out/frames --every 20 \
        /robot_frasky/camera/color/image_raw /robot_frasky/detection_img
"""
import argparse
import os
import time

import cv2
import numpy as np
import rospy
from sensor_msgs.msg import Image


def to_bgr(m):
    a = np.frombuffer(m.data, np.uint8).reshape(m.height, m.width, -1)
    if m.encoding.lower().startswith("rgb"):
        a = a[..., ::-1]
    return a


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("topics", nargs="+")
    ap.add_argument("--out", required=True)
    ap.add_argument("--every", type=float, default=20.0)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    rospy.init_node("frame_logger", anonymous=True)
    last = {}

    def make_cb(topic):
        tag = topic.strip("/").replace("/", "_")

        def cb(m):
            now = time.time()
            if now - last.get(topic, 0) < a.every:
                return
            last[topic] = now
            try:
                name = "%s/%s_%07.1f.jpg" % (a.out, tag, rospy.get_time())
                cv2.imwrite(name, to_bgr(m), [cv2.IMWRITE_JPEG_QUALITY, 85])
            except Exception as e:  # keep logging even if one frame is odd
                rospy.logwarn("frame save failed on %s: %s", topic, e)
        return cb

    for t in a.topics:
        rospy.Subscriber(t, Image, make_cb(t), queue_size=1, buff_size=2 ** 24)
    rospy.spin()


if __name__ == "__main__":
    main()
