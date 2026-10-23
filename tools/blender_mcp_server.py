#!/usr/bin/env python3
# blender_mcp_server.py — minimal MCP server for the Niobium Blender bridge.
# Exposes Blender control tools to OpenCode via MCP (stdio), talking to the local socket
# addon (niobium_bridge_addon.py) on 127.0.0.1:9876. No telemetry, no external network.
#
# Configure in opencode.json:
#   "mcp": { "blender": { "type": "local",
#       "command": ["<python>", "<repo>/tools/blender_mcp_server.py"], "enabled": true } }

import json
import socket

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("blender")

HOST = "127.0.0.1"
PORT = 9876


def call_blender(payload, timeout=120):
    s = socket.create_connection((HOST, PORT), timeout=timeout)
    try:
        s.sendall(json.dumps(payload).encode("utf-8"))
        data = b""
        while True:
            chunk = s.recv(65536)
            if not chunk:
                break
            data += chunk
            if len(chunk) < 65536:
                break
        return json.loads(data.decode("utf-8"))
    finally:
        s.close()


@mcp.tool()
def execute_blender_code(code: str) -> str:
    """Execute Python code inside Blender (bpy available) and return the result/stdout."""
    try:
        resp = call_blender({"type": "execute", "code": code})
        if resp.get("ok"):
            out = (resp.get("stdout", "") or "").strip()
            res = (resp.get("result", "") or "").strip()
            return ("%s\n%s" % (out, res)).strip() if (out or res) else "ok"
        return "ERROR: %s\n%s" % (resp.get("error", ""), resp.get("traceback", ""))
    except Exception as e:  # noqa: BLE001
        return "ERROR (connection): %s" % str(e)


@mcp.tool()
def get_scene_info() -> str:
    """Get a summary of the current Blender scene (objects, meshes, armatures, materials)."""
    try:
        resp = call_blender({"type": "get_scene"})
        if resp.get("ok"):
            return json.dumps(resp.get("scene", {}), indent=2)
        return "ERROR: %s" % resp.get("error", "")
    except Exception as e:  # noqa: BLE001
        return "ERROR (connection): %s" % str(e)


@mcp.tool()
def ping_blender() -> str:
    """Check whether Blender (with the bridge addon) is running and reachable."""
    try:
        resp = call_blender({"type": "ping"})
        return "pong" if resp.get("ok") else ("ERROR: %s" % resp.get("error", ""))
    except Exception as e:  # noqa: BLE001
        return "ERROR (not reachable): %s" % str(e)


if __name__ == "__main__":
    mcp.run()
