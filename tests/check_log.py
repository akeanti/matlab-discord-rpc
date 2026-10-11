"""Checks on what the bridge sent to the fake Discord during the tests.

    python check_log.py LOG
"""
import json
import sys

frames = [json.loads(l) for l in open(sys.argv[1]) if '"op"' in l]
sets = [f["body"] for f in frames if f["op"] == 1]
checks = {
    "handshakes use protocol v1": all(f["body"].get("v") == 1 for f in frames if f["op"] == 0),
    "pings are answered": any(f["op"] == 4 for f in frames),
    "every update carries the MATLAB pid": all(isinstance(b["args"].get("pid"), int) for b in sets),
    "updates have nonces": all(b.get("nonce") for b in sets),
    "pause and stop clear the activity": sum("activity" not in b["args"] for b in sets) >= 2,
}
for name, ok in checks.items():
    print(("ok    " if ok else "FAIL  ") + name)
sys.exit(0 if all(checks.values()) else 1)
