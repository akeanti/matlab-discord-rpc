"""A tiny stand-in for the Discord client, used by the bridge tests.

Speaks the Discord IPC framing (op code + length + JSON) over TCP instead of
a named pipe, so the tests run anywhere. The bridge talks TCP when it is
built with -define:DRPC_TCP_TEST.

    python fake_discord.py PORT LOG CONTROL

Every frame the bridge sends is appended to LOG as one JSON line.
Write "drop" to CONTROL to cut the connection, "quit" to stop the server.
"""
import json
import socket
import struct
import sys
import threading
import time

port, log_path, ctl_path = int(sys.argv[1]), sys.argv[2], sys.argv[3]
VALID_ID = "1558853253620564039"  # any 17-20 digit id works the same
lock = threading.Lock()
clients = []


def log(entry):
    with lock, open(log_path, "a") as f:
        f.write(json.dumps({"t": round(time.time(), 2), **entry}) + "\n")


def send(conn, op, obj):
    data = json.dumps(obj).encode()
    conn.sendall(struct.pack("<ii", op, len(data)) + data)


def recv_exact(conn, n):
    buf = b""
    while len(buf) < n:
        chunk = conn.recv(n - len(buf))
        if not chunk:
            raise ConnectionError
        buf += chunk
    return buf


def handle(conn):
    clients.append(conn)
    try:
        while True:
            op, ln = struct.unpack("<ii", recv_exact(conn, 8))
            body = json.loads(recv_exact(conn, ln).decode())
            log({"op": op, "body": body})
            if op == 0:
                if body.get("client_id") != VALID_ID:
                    send(conn, 2, {"code": 4000, "message": "Invalid Client ID"})
                    conn.close()
                    return
                send(conn, 1, {"cmd": "DISPATCH", "evt": "READY", "nonce": None,
                               "data": {"v": 1, "user": {"id": "1", "username": "akeanti", "global_name": None}}})
                send(conn, 3, {"ping": 1})
            elif op == 1 and body.get("cmd") == "SET_ACTIVITY":
                act = body["args"].get("activity")
                if act and act.get("details") == "BAD":
                    send(conn, 1, {"cmd": "SET_ACTIVITY", "evt": "ERROR", "nonce": body["nonce"],
                                   "data": {"code": 4000, "message": "child \"activity\" fails"}})
                else:
                    send(conn, 1, {"cmd": "SET_ACTIVITY", "evt": None, "nonce": body["nonce"], "data": act})
    except (ConnectionError, OSError):
        pass
    finally:
        if conn in clients:
            clients.remove(conn)
        log({"event": "client_gone"})


srv = socket.socket()
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("127.0.0.1", port))
srv.listen()
srv.settimeout(0.2)
log({"event": "listening"})
while True:
    try:
        cmd = open(ctl_path).read().strip()
    except OSError:
        cmd = ""
    if cmd == "quit":
        break
    if cmd == "drop":
        open(ctl_path, "w").close()
        for c in list(clients):
            try:
                c.shutdown(socket.SHUT_RDWR)
                c.close()
            except OSError:
                pass
    try:
        conn, _ = srv.accept()
        conn.settimeout(None)
        threading.Thread(target=handle, args=(conn,), daemon=True).start()
    except socket.timeout:
        pass
for c in list(clients):
    c.close()
srv.close()
