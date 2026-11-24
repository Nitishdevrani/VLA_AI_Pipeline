#!/usr/bin/env python3
"""Record an image topic to an MP4 that plays at simulated speed (one video frame per camera frame).

The camera publishes at a fixed rate in SIM time (30 Hz for the arm camera), so writing every frame
at that rate gives a video in sim time, whatever the real-time factor was. Stops on Ctrl-C / SIGINT.

    python3 record_topic.py /robot_frasky/camera/color/image_raw /tmp/task3/robotcam.mp4 --fps 30 --label "robot camera"
"""
import argparse

import cv2
import numpy as np
import rospy
from sensor_msgs.msg import Image


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("topic")
    ap.add_argument("out")
    ap.add_argument("--fps", type=float, default=30.0, help="the topic's publish rate in sim time")
    ap.add_argument("--label", default="")
    a = ap.parse_args()
    rospy.init_node("record_topic", anonymous=True)
    st = {"w": None, "n": 0}

    def cb(m):
        img = np.frombuffer(m.data, np.uint8).reshape(m.height, m.width, -1)
        img = img[..., ::-1].copy() if m.encoding.lower().startswith("rgb") else img.copy()
        if st["w"] is None:
            st["w"] = cv2.VideoWriter(a.out, cv2.VideoWriter_fourcc(*"mp4v"), a.fps, (m.width, m.height))
        text = "%s  sim t=%.1f s" % (a.label, m.header.stamp.to_sec())
        cv2.putText(img, text, (8, m.height - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (0, 0, 0), 3)
        cv2.putText(img, text, (8, m.height - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (255, 255, 255), 1)
        st["w"].write(img)
        st["n"] += 1

    rospy.Subscriber(a.topic, Image, cb, queue_size=30, buff_size=2 ** 26)
    rospy.spin()
    if st["w"] is not None:
        st["w"].release()
    print("wrote %d frames to %s" % (st["n"], a.out))


if __name__ == "__main__":
    main()
