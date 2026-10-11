#!/usr/bin/env bash
# Build the bridge in test mode and run it against a fake Discord.
# Needs mono (mcs + mono) and python3. On Windows, use tests/run.ps1.
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

python3 "$here/check_log.py" "$work/log.jsonl" || status=1

exit $status
