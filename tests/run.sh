#!/usr/bin/env bash
# Build the bridge in test mode and run it against a fake Discord.
# Needs mono (mcs + mono) and python3.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d)"
trap 'echo quit > "$work/control" 2>/dev/null || true; rm -rf "$work"' EXIT
port=46300

# C# 5 is what the csc.exe that ships with Windows understands
mcs -langversion:5 -warnaserror -target:library -r:System.Core.dll \
    -out:"$work/bridge.dll" "$here/../DiscordRPC/DrpcBridge.cs"
mcs -langversion:5 -define:DRPC_TCP_TEST -r:System.Core.dll \
    -out:"$work/tests.exe" "$here/../DiscordRPC/DrpcBridge.cs" "$here/BridgeTests.cs"

mono "$work/tests.exe" "$port" "$work/control" offline

: > "$work/control"
python3 "$here/fake_discord.py" "$port" "$work/log.jsonl" "$work/control" &
server=$!
sleep 0.5
status=0
mono "$work/tests.exe" "$port" "$work/control" main || status=1
mono "$work/tests.exe" "$port" "$work/control" badid || status=1
echo quit > "$work/control"
wait "$server" || true

python3 - "$work/log.jsonl" <<'EOF' || status=1
import json, sys
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
EOF

exit $status
