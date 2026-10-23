# Blender + MCP + character pipeline

Niobium's character is authored in **Blender** and consumed by **Godot** as glTF. A local
**MCP** bridge lets the agent (and the owner) drive Blender interactively. Everything is
local and private — no telemetry.

## Installed toolchain

| Tool | Version | Location | Purpose |
|---|---|---|---|
| Blender | 4.5.3 LTS | `%LOCALAPPDATA%\Programs\blender-4.5.3-windows-x64\blender.exe` | 3D authoring |
| Python | 3.12.10 | `%LOCALAPPDATA%\Programs\Python\Python312\python.exe` | MCP server + scripting |
| `mcp` SDK | 1.30.0 | pip | MCP server framework |

Blender's bundled Python (3.11.11) already ships `requests`.

## The MCP bridge (privacy-first)

The popular `mcp-for-blender` package ships **telemetry enabled by default** (a hardcoded
Supabase endpoint) — that violates Niobium's "no telemetry" rule, so it is **not used**. Instead:

- **Blender addon** — `avatars/blender/niobium_bridge_addon.py`, installed to
  `%APPDATA%\Blender Foundation\Blender\4.5\scripts\addons\niobium_bridge.py`. Runs a loopback
  socket server on `127.0.0.1:9876` that answers `ping`, `get_scene`, and `execute` (runs
  owner-authorized Python with `bpy` in Blender). No network egress beyond loopback.
- **MCP server** — `tools/blender_mcp_server.py`, a `FastMCP` stdio server exposing
  `blender_ping_blender`, `blender_get_scene_info`, and `blender_execute_blender_code`.
- **OpenCode config** — `~/.config/opencode/opencode.json`:

  ```jsonc
  {
    "$schema": "https://opencode.ai/config.json",
    "mcp": {
      "servers": {
        "blender": {
          "type": "local",
          "command": [
            "<python>",
            "<repo>/tools/blender_mcp_server.py"
          ]
        }
      }
    }
  }
  ```

  (Absolute paths are machine-specific; the repo does not commit `opencode.json`.)

### Using it

1. Open Blender and enable **"Niobium Blender Bridge"** in Edit → Preferences → Add-ons
   (or run the headless keep-alive: `blender --background --python <keepalive.py>`).
2. The MCP tools `blender_ping_blender`, `blender_get_scene_info`,
   `blender_execute_blender_code` become available to the agent.

> Note: Blender's `bpy.context` is main-thread/foreground-only; the bridge reads `bpy.data`
> (thread-safe). Object *creation* from a background thread can be flaky — prefer scripted
> authoring (below) for reproducible changes.

## Scripted character pipeline (reproducible, no Blender UI needed)

`avatars/blender/create_violet.py` builds the **Violet** character headlessly and exports it:

```sh
$env:NIOBIUM_AVATAR_OUT = "<repo>/avatars/generated"
blender --background --factory-startup --python avatars/blender/create_violet.py
```

Outputs (gitignored large binaries; regenerate from the script):
- `avatars/generated/violet.blend` — editable source.
- `avatars/generated/violet.glb` — glTF for Godot (copied to `app/assets/characters/violet.glb`).

What the script produces:
- A humanoid **armature** whose core bone names match `RigProfile.HUMAN_BONES`, plus finger
  bones (`Thumb/Index/Middle/Ring/Pinky .01/.02/.03` per hand) for controllable hands.
- An **organic body** (Skin modifier + Subdivision Surface), auto-skinned to the armature.
- Separate **face meshes** (eye whites / iris / pupil, brows, mouth) parented to `Head`.
- **Mesh hair** and a **bodysuit** (head cut away so the face shows).
- **Face shape keys**: `jaw_open`, `blink_L`, `blink_R`, `smile`, `frown`, `brow_raise`.
- **PBR base-color materials** (skin violet, violet-black outfit, near-black hair, cyan iris).

In Godot, `RiggedAvatar` (`app/scripts/rig/rigged_avatar.gd`) loads the glTF, exposes the
skeleton + blend shapes through the same interface the animation/speech systems expect, and
`CompanionStage` applies the cel shader (`app/shaders/toon.gdshader`) to body/outfit/hair.

## Verification

- `godot --headless --path app --script res://tests/test_gltf.gd` — asserts the imported glTF
  has all core bones + finger bones and the 6 face morphs.
- `godot --path app --script res://tools/capture_frame.gd` — renders the scene to
  `user://capture.png` (local Vulkan) for pixel inspection; screenshots land in
  `docs/screenshots/`.

## Known limitations (honest)

- The body is a Skin-modifier base — good proportions, but not a sculpted/high-detail figure.
- Viseme lip shapes (`lips_wide`/`lips_round`/`lips_f`/`lips_close`) are mapped in the rig
  manifest but not yet authored as shape keys; speech currently drives `jaw_open` only.
- Hair is a simple mesh (no strands); a proper hair system is future work.
- No textures yet (flat base colors); UVs are missing (Godot logs a tangent warning).
