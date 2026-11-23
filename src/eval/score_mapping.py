#!/usr/bin/env python3
"""Score a mapping JSON against the simulator ground truth (evaluation only).

The ground truth is read from the world file and must never be copied into a submission.

Reports:
  official   unique IDs in the JSON / 270   (the 25 Nov metric: "grapes listed in your JSON")
  verified   distinct real grapes the entries actually point at / 270
  plus duplicates, unmatched entries, whether entry IDs equal simulator IDs, and position error.

Matching (map frame): an entry with a non-zero grape_pose is matched to the nearest grape in 3-D.
Otherwise its robot_pose is used: the robot stands ~1.1 m beside its grape, at the same x,
so the match is the grape 0.6-1.8 m away in y with the closest x.

    python3 score_mapping.py mapping.json [--gt grapes_ground_truth.json] [--json metrics.json]
"""
import argparse
import json
import math
import os
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_GT = os.path.join(HERE, "..", "..", "docs", "source", "simulator", "grapes_ground_truth.json")
N_TOTAL = 270
GRAPE_TOL = 0.15   # m, 3-D match radius for grape_pose (grapes are 0.225 m apart along x)
ROBOT_X_TOL = 0.11  # m, half the grape spacing
ROBOT_Y_RANGE = (0.6, 1.8)


def xyz(pose):
    p = (pose or {}).get("position", {})
    return [float(p.get(k, 0.0)) for k in ("x", "y", "z")]


def is_zero(v):
    return all(abs(c) < 1e-9 for c in v)


def match(entry, gt):
    g = xyz(entry.get("grape_pose"))
    if not is_zero(g):
        best = min(gt, key=lambda t: math.dist(g, t["map"]))
        d = math.dist(g, best["map"])
        return (best["id"], d, "grape_pose") if d <= GRAPE_TOL else (None, d, "grape_pose")
    r = xyz(entry.get("robot_pose"))
    if is_zero(r):
        return None, None, "no_pose"
    lo, hi = ROBOT_Y_RANGE
    cands = [t for t in gt if lo <= abs(t["map"][1] - r[1]) <= hi]
    if not cands:
        return None, None, "robot_pose"
    best = min(cands, key=lambda t: abs(t["map"][0] - r[0]))
    dx = abs(best["map"][0] - r[0])
    return (best["id"], dx, "robot_pose") if dx <= ROBOT_X_TOL else (None, dx, "robot_pose")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mapping")
    ap.add_argument("--gt", default=DEFAULT_GT)
    ap.add_argument("--json", default="", help="write metrics here")
    a = ap.parse_args()

    entries = json.load(open(a.mapping))
    gt = json.load(open(a.gt))
    assert len(gt) == N_TOTAL, len(gt)

    ids = [e.get("id") for e in entries]
    unique_ids = set(ids)
    rows, hits = [], Counter()
    for e in entries:
        gid, err, how = match(e, gt)
        rows.append((e.get("id"), gid, err, how))
        if gid is not None:
            hits[gid] += 1

    matched = [r for r in rows if r[1] is not None]
    errs = [r[2] for r in matched]
    m = {
        "file": os.path.abspath(a.mapping),
        "entries": len(entries),
        "unique_ids": len(unique_ids),
        "official_pct": round(100 * len(unique_ids) / N_TOTAL, 1),
        "verified_grapes": len(hits),
        "verified_pct": round(100 * len(hits) / N_TOTAL, 1),
        "duplicate_entries": sum(c - 1 for c in hits.values()),
        "unmatched_entries": len(entries) - len(matched),
        "id_equals_sim_id": sum(1 for r in matched if r[0] == r[1]),
        "matched_by": dict(Counter(r[3] for r in matched)),
        "mean_err_m": round(sum(errs) / len(errs), 3) if errs else None,
        "max_err_m": round(max(errs), 3) if errs else None,
        "per_row_side": {},
    }
    for k in range(6):  # 45 grapes per row side, IDs 1-45, 46-90, ...
        lo, hi = 45 * k + 1, 45 * k + 45
        m["per_row_side"][f"{lo}-{hi}"] = sum(1 for g in hits if lo <= g <= hi)

    print(f"entries in JSON          {m['entries']}")
    print(f"official  (unique IDs)   {m['unique_ids']}/270 = {m['official_pct']} %")
    print(f"verified  (real grapes)  {m['verified_grapes']}/270 = {m['verified_pct']} %")
    print(f"duplicates / unmatched   {m['duplicate_entries']} / {m['unmatched_entries']}")
    print(f"entry id == sim id       {m['id_equals_sim_id']}/{len(matched)}")
    print(f"matched by               {m['matched_by']}")
    print(f"position error (m)       mean {m['mean_err_m']}  max {m['max_err_m']}")
    print("per row side (sim IDs)   " + "  ".join(f"{k}:{v}" for k, v in m["per_row_side"].items()))
    if a.json:
        json.dump(m, open(a.json, "w"), indent=1)


if __name__ == "__main__":
    main()
