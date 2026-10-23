# Character assets and validation

## Honest status

An authored character **"Violet"** now exists (see `docs/BLENDER_MCP.md`): a Blender-built
humanoid (armature matching `RigProfile.HUMAN_BONES` + finger bones, organic Skin-modifier
body, face meshes, hair, bodysuit, and face shape keys) exported to glTF and loaded by Godot's
`RiggedAvatar`. The source script (`avatars/blender/create_violet.py`) and `.blend` are in the
repo. It is a **real authored base**, but not yet "stunning": no sculpt/texture detail, hair is
a simple mesh, and lip viseme shape keys are not yet authored — those are open refinement tasks.

## The outstanding art task (open)

Production deliverables still required (brief §5), none fabricated:

- Editable Blender source, textures and export settings.
- Correctly skinned humanoid body with sensible bone names and scale.
- Face morphs: jaw/lips, blink L/R, a useful expression set.
- Viseme mapping for the chosen speech pipeline; custom morphs where needed.
- Independently controllable eyes, head, neck, spine, shoulders, hands, fingers.
- Hair/accessory secondary motion with collision limits.
- Coherent skin/eye/hair/clothing materials; sensible alpha overdraw.
- Mobile and desktop quality levels, texture sizes, meshes.
- Named camera anchors: portrait, bust, seated/waist, full body.
- License/provenance metadata and stable asset IDs.
- Animation clips with root-motion policy, loop flags, retarget profile.

Anime and realistic looks may share skeleton conventions + identity metadata but may need
different meshes/materials/rig tuning/animations. No automatic photoreal conversion is promised.

## Rig contract (what the runtime expects)

`avatars/rigs/engineering_rig.json` declares the `RigProfile` used by `AnimationDirector`:

- **Bone conventions:** standard humanoid names (`Hips`, `Spine`, `Chest`, `Neck`, `Head`,
  `Shoulder.L/R`, `UpperArm.L/R`, `LowerArm.L/R`, `Hand.L/R`, `UpperLeg.L/R`, `LowerLeg.L/R`,
  `Foot.L/R`, plus `Eye.L/R` for gaze). A drop-in glTF/VRM must map to these names via its own
  profile; unknown bones are reported, not guessed.
- **Morph channels:** `jaw_open`, `lips_<viseme>` (the viseme set), `blink_L`, `blink_R`,
  `brow_raise`, `smile`, `frown`, plus a neutral. A profile maps provider viseme IDs → morph
  channels.
- **Camera anchors:** `portrait`, `bust`, `waist`, `full` (named `Node3D`/`Marker3D` targets).

## Import validation

`AvatarImporter` produces a `ValidationReport` with errors/warnings:

- missing bones, unknown expressions, unsupported extensions
- texture/mesh budget violations (mobile vs desktop budgets)
- scale/unit sanity, morph-channel presence for the chosen speech pipeline

A malformed avatar must **fail gracefully**: the previous working avatar stays loaded, the
workspace is not destroyed, and the report is surfaced. Import is atomic (validate → stage →
activate).

## Rights and provenance

Every avatar manifest carries `license`, `provenance`, `asset_id`, and a `rights_cleared`
flag. No character is ever downloaded with unsuitable redistribution or content permissions.
`fixtures/` contains only rights-cleared or redacted test data.
