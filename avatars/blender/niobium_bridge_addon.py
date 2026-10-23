# niobium_bridge_addon.py — minimal, privacy-respecting Blender MCP bridge.
# A Blender addon that runs a local socket server (127.0.0.1:9876) and answers JSON commands
# to query the scene or execute owner-authorized Python in Blender. No telemetry, no network
# egress beyond the loopback socket. Install by copying this file into Blender's
# scripts/addons/ directory and enabling "Niobium Blender Bridge" in Preferences > Add-ons.

import bpy
import json
import socket
import threading
import traceback
import io
from contextlib import redirect_stdout

bl_info = {
    "name": "Niobium Blender Bridge",
    "author": "Niobium",
    "version": (1, 0, 0),
    "blender": (4, 0, 0),
    "location": "View3D > Sidebar",
    "description": "Local socket bridge for the Niobium character pipeline (no telemetry).",
    "category": "Interface",
}

HOST = "127.0.0.1"
PORT = 9876

_server_thread = None
_running = False


def get_scene_info():
    # Only touch bpy.data (thread-safe); bpy.context is main-thread/foreground-only.
    return {
        "objects": [o.name for o in bpy.data.objects],
        "meshes": [m.name for m in bpy.data.meshes],
        "armatures": [a.name for a in bpy.data.armatures],
        "materials": [m.name for m in bpy.data.materials],
        "object_count": len(bpy.data.objects),
    }


def execute(code):
    buf = io.StringIO()
    try:
        with redirect_stdout(buf):
            result = eval(code, {"bpy": bpy, "__builtins__": __builtins__})
        return {"ok": True, "result": repr(result), "stdout": buf.getvalue()}
    except Exception as e:  # noqa: BLE001
        return {"ok": False, "error": str(e), "traceback": traceback.format_exc()}


def _recv_all(conn):
    data = b""
    while True:
        chunk = conn.recv(65536)
        if not chunk:
            break
        data += chunk
        if len(chunk) < 65536:
            break
    return data


def handle(conn):
    try:
        req = json.loads(_recv_all(conn).decode("utf-8"))
        cmd = req.get("type", "")
        if cmd == "execute":
            resp = execute(req.get("code", ""))
        elif cmd == "get_scene":
            resp = {"ok": True, "scene": get_scene_info()}
        elif cmd == "ping":
            resp = {"ok": True, "pong": True}
        else:
            resp = {"ok": False, "error": "unknown command: " + cmd}
        conn.sendall(json.dumps(resp).encode("utf-8"))
    except Exception as e:  # noqa: BLE001
        try:
            conn.sendall(json.dumps({"ok": False, "error": str(e)}).encode("utf-8"))
        except OSError:
            pass
    finally:
        conn.close()


def server_loop():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((HOST, PORT))
    s.listen(4)
    global _running
    _running = True
    print("Niobium Blender Bridge listening on %s:%d" % (HOST, PORT))
    while _running:
        try:
            conn, _ = s.accept()
            threading.Thread(target=handle, args=(conn,), daemon=True).start()
        except OSError:
            break
    s.close()


def register():
    global _server_thread, _running
    if _server_thread is not None:
        return
    _running = True
    _server_thread = threading.Thread(target=server_loop, daemon=True)
    _server_thread.start()


def unregister():
    global _running
    _running = False


if __name__ == "__main__":
    register()
