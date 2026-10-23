# create_violet.py — Niobium "Violet" character authoring script.
# Run headless:
#   blender --background --factory-startup --python create_violet.py
#
# Produces an editable .blend source and a .glb for Godot. This is a *real* authored
# character: a humanoid armature (bone names matching the Godot RigProfile), an organic
# body mesh (Skin modifier + Subsurf), separate eye/brow/mouth meshes, mesh hair, a bodysuit
# outfit, face shape keys (visemes/blink/expressions), and PBR base-color materials.
#
# Art direction: adult, cyberpunk-manga; violet-black surfaces; cyan accents. Cel shading is
# applied in Godot (app/shaders/toon.gdshader), not baked here.

import bpy
import math
import mathutils
import os

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

OUT_DIR = os.environ.get("NIOBIUM_AVATAR_OUT", "")
BASE_NAME = "Violet"

# Armature bone specs: (name, head, tail, parent, use_connect)
# Blender is +Z-up, character faces -Y. Bone names match app RigProfile.HUMAN_BONES plus
# finger bones for independently controllable hands.
def bone(name, head, tail, parent=None, connect=False):
    return (name, mathutils.Vector(head), mathutils.Vector(tail), parent, connect)

ARMATURE_BONES = [
    bone("Hips",       (0.00, 0.00, 0.95), (0.00, 0.00, 1.08), None, False),
    bone("Spine",      (0.00, 0.00, 1.08), (0.00, 0.00, 1.22), "Hips", True),
    bone("Chest",      (0.00, 0.00, 1.22), (0.00, 0.00, 1.42), "Spine", True),
    bone("Neck",       (0.00, 0.00, 1.42), (0.00, 0.00, 1.50), "Chest", True),
    bone("Head",       (0.00, 0.00, 1.50), (0.00, 0.00, 1.68), "Neck", True),

    bone("Shoulder.L", (-0.07, 0.00, 1.40), (-0.16, 0.00, 1.40), "Chest", False),
    bone("UpperArm.L", (-0.16, 0.00, 1.40), (-0.16, 0.00, 1.14), "Shoulder.L", True),
    bone("LowerArm.L", (-0.16, 0.00, 1.14), (-0.16, 0.00, 0.90), "UpperArm.L", True),
    bone("Hand.L",     (-0.16, 0.00, 0.90), (-0.16, 0.00, 0.80), "LowerArm.L", True),
    bone("Shoulder.R", (0.07, 0.00, 1.40), (0.16, 0.00, 1.40), "Chest", False),
    bone("UpperArm.R", (0.16, 0.00, 1.40), (0.16, 0.00, 1.14), "Shoulder.R", True),
    bone("LowerArm.R", (0.16, 0.00, 1.14), (0.16, 0.00, 0.90), "UpperArm.R", True),
    bone("Hand.R",     (0.16, 0.00, 0.90), (0.16, 0.00, 0.80), "LowerArm.R", True),

    bone("UpperLeg.L", (-0.09, 0.00, 0.95), (-0.09, 0.00, 0.52), "Hips", False),
    bone("LowerLeg.L", (-0.09, 0.00, 0.52), (-0.09, 0.00, 0.12), "UpperLeg.L", True),
    bone("Foot.L",     (-0.09, 0.00, 0.12), (-0.09, -0.16, 0.10), "LowerLeg.L", False),
    bone("UpperLeg.R", (0.09, 0.00, 0.95), (0.09, 0.00, 0.52), "Hips", False),
    bone("LowerLeg.R", (0.09, 0.00, 0.52), (0.09, 0.00, 0.12), "UpperLeg.R", True),
    bone("Foot.R",     (0.09, 0.00, 0.12), (0.09, -0.16, 0.10), "LowerLeg.R", False),

    bone("Eye.L",      (-0.035, -0.085, 1.58), (-0.035, -0.11, 1.58), "Head", False),
    bone("Eye.R",      (0.035, -0.085, 1.58), (0.035, -0.11, 1.58), "Head", False),
]

# Fingers (side = "L"/"R", base z at hand height). 3 bones each: 01 (metacarpal-ish) -> 02 -> 03.
FINGERS = {
    "Thumb":  0.02,
    "Index":  0.00,
    "Middle": -0.02,
    "Ring":   -0.04,
    "Pinky":  -0.06,
}


def add_finger_bones(bones, side, sign):
    hand_z = 0.90
    hand_x = sign * 0.16
    for name, y_off in FINGERS.items():
        base_y = -0.02 + y_off  # along -Y (fingers point forward)
        b1 = "%s.%s.01" % (name, side)
        b2 = "%s.%s.02" % (name, side)
        b3 = "%s.%s.03" % (name, side)
        # finger length ~0.055 per segment
        bones.append(bone(b1, (hand_x, base_y, hand_z), (hand_x, base_y - 0.055, hand_z), "Hand." + side, False))
        bones.append(bone(b2, (hand_x, base_y - 0.055, hand_z), (hand_x, base_y - 0.105, hand_z), b1, True))
        bones.append(bone(b3, (hand_x, base_y - 0.105, hand_z), (hand_x, base_y - 0.15, hand_z), b2, True))


for side, sign in (("L", -1.0), ("R", 1.0)):
    add_finger_bones(ARMATURE_BONES, side, sign)


# ---------------------------------------------------------------------------
# Scene reset
# ---------------------------------------------------------------------------

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


# ---------------------------------------------------------------------------
# Armature
# ---------------------------------------------------------------------------

def build_armature():
    arm = bpy.data.armatures.new(BASE_NAME + "Armature")
    arm_obj = bpy.data.objects.new(BASE_NAME, arm)
    bpy.context.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode='EDIT')
    for spec in ARMATURE_BONES:
        name, head, tail, parent, connect = spec
        eb = arm.edit_bones.new(name)
        eb.head = head
        eb.tail = tail
        if parent:
            eb.parent = arm.edit_bones[parent]
            eb.use_connect = connect
    bpy.ops.object.mode_set(mode='OBJECT')
    return arm_obj


# ---------------------------------------------------------------------------
# Body via Skin modifier
# ---------------------------------------------------------------------------

def build_body(arm_obj):
    # A vertex chain that the Skin modifier inflates into a smooth organic body.
    # Radii: (x, y) perpendicular to the chain direction.
    verts = [
        (0.00, 0.00, 0.00),   # 0 pelvis/root
        (0.00, 0.00, 0.95),   # 1 hips
        (0.00, 0.00, 1.30),   # 2 chest
        (0.00, 0.00, 1.50),   # 3 neck
        (0.00, 0.00, 1.66),   # 4 head center
        (0.00, 0.00, 1.86),   # 5 head top
        (-0.16, 0.00, 1.40),  # 6 shoulder L
        (-0.16, 0.00, 1.14),  # 7 elbow L
        (-0.16, 0.00, 0.90),  # 8 wrist L
        (0.16, 0.00, 1.40),   # 9 shoulder R
        (0.16, 0.00, 1.14),   # 10 elbow R
        (0.16, 0.00, 0.90),   # 11 wrist R
        (-0.09, 0.00, 0.95),  # 12 hip L
        (-0.09, 0.00, 0.50),  # 13 knee L
        (-0.09, 0.00, 0.10),  # 14 ankle L
        (0.09, 0.00, 0.95),   # 15 hip R
        (0.09, 0.00, 0.50),   # 16 knee R
        (0.09, 0.00, 0.10),   # 17 ankle R
    ]
    edges = [
        (0, 1), (1, 2), (2, 3), (3, 4), (4, 5),           # spine + head
        (2, 6), (6, 7), (7, 8),                            # arm L
        (2, 9), (9, 10), (10, 11),                         # arm R
        (1, 12), (12, 13), (13, 14),                       # leg L
        (1, 15), (15, 16), (16, 17),                       # leg R
    ]
    radii = {
        0: (0.13, 0.13),
        1: (0.12, 0.12),
        2: (0.11, 0.11),
        3: (0.06, 0.06),
        4: (0.085, 0.09),   # head slightly oval
        5: (0.05, 0.05),
        6: (0.045, 0.045), 7: (0.035, 0.035), 8: (0.025, 0.025),
        9: (0.045, 0.045), 10: (0.035, 0.035), 11: (0.025, 0.025),
        12: (0.055, 0.055), 13: (0.045, 0.045), 14: (0.03, 0.03),
        15: (0.055, 0.055), 16: (0.045, 0.045), 17: (0.03, 0.03),
    }
    mesh = bpy.data.meshes.new(BASE_NAME + "Body")
    mesh.from_pydata(verts, edges, [])
    mesh.update()
    obj = bpy.data.objects.new(BASE_NAME + "Body", mesh)
    bpy.context.collection.objects.link(obj)
    skin = obj.modifiers.new("Skin", 'SKIN')
    # Set skin radii (the Skin modifier creates the skin layer on the mesh).
    for i, (rx, ry) in radii.items():
        mesh.skin_vertices[0].data[i].radius = (rx, ry)
    subsurf = obj.modifiers.new("Subsurf", 'SUBSURF')
    subsurf.levels = 2
    subsurf.render_levels = 2

    # Apply Skin + Subsurf so the mesh is concrete and can be skinned.
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=skin.name)
    bpy.ops.object.modifier_apply(modifier=subsurf.name)

    # Skin to the armature.
    obj.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.parent_set(type='ARMATURE_AUTO')
    obj.select_set(False)
    arm_obj.select_set(False)
    return obj


# ---------------------------------------------------------------------------
# Face meshes (eyes, brows, mouth) parented to the Head bone
# ---------------------------------------------------------------------------

def mesh_sphere(name, radius, location, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=location)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = mathutils.Vector(scale)
    return obj


def mesh_cylinder(name, radius, depth, location):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, location=location)
    obj = bpy.context.active_object
    obj.name = name
    return obj


def build_face(arm_obj):
    objs = []
    # Eyes: white + iris + pupil, positioned in front of the head (-Y is forward).
    for side, sign in (("L", -1.0), ("R", 1.0)):
        ey = (sign * 0.035, -0.088, 1.58)
        white = mesh_sphere("EyeWhite.%s" % side, 0.032, ey)
        white.scale = (1.0, 1.0, 0.6)
        iris = mesh_sphere("Iris.%s" % side, 0.017, (sign * 0.035, -0.105, 1.58))
        iris.scale = (0.8, 1.0, 0.5)
        pupil = mesh_sphere("Pupil.%s" % side, 0.008, (sign * 0.035, -0.112, 1.58))
        objs += [white, iris, pupil]
    # Brows.
    for side, sign in (("L", -1.0), ("R", 1.0)):
        brow = mesh_cylinder("Brow.%s" % side, 0.006, 0.075, (sign * 0.037, -0.082, 1.635))
        brow.rotation_euler = (math.radians(sign * 12), 0, 0)
        objs.append(brow)
    # Mouth: a flattened dark shape.
    mouth = mesh_sphere("Mouth", 0.028, (0.0, -0.085, 1.465))
    mouth.scale = (1.3, 0.35, 0.5)
    objs.append(mouth)

    for o in objs:
        o.parent = arm_obj
        o.parent_type = 'ARMATURE'
        o.parent_bone = "Head"
        # store for later material assignment
    return objs


# ---------------------------------------------------------------------------
# Hair (mesh: scalp cap + swept bob)
# ---------------------------------------------------------------------------

def build_hair(arm_obj):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.10, location=(0, 0, 1.60))
    hair = bpy.context.active_object
    hair.name = BASE_NAME + "Hair"
    hair.scale = (1.0, 0.95, 1.05)
    hair.location = (0, 0.02, 1.62)
    # Elongate the back for a bob.
    subsurf = hair.modifiers.new("Subsurf", 'SUBSURF')
    subsurf.levels = 2
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.transform.translate(value=(0, 0.10, -0.03))
    bpy.ops.object.mode_set(mode='OBJECT')
    hair.parent = arm_obj
    hair.parent_type = 'ARMATURE'
    hair.parent_bone = "Head"
    return hair


# ---------------------------------------------------------------------------
# Outfit: bodysuit = body scaled up slightly, with a clothing material.
# ---------------------------------------------------------------------------

def build_outfit(body_obj, arm_obj):
    # Duplicate the body, scale outward, give it a bodysuit material, and cut away the head
    # so the face/skin remains visible.
    outfit = body_obj.copy()
    outfit.data = body_obj.data.copy()
    outfit.name = BASE_NAME + "Outfit"
    bpy.context.collection.objects.link(outfit)
    outfit.scale = (1.012, 1.012, 1.012)
    outfit.parent = arm_obj
    outfit.parent_type = 'ARMATURE'
    # Carry over the armature modifier with same weights.
    for m in outfit.modifiers:
        if m.type == 'ARMATURE':
            m.object = arm_obj
    # Delete vertices above the neck so the head is not a "mask".
    bpy.context.view_layer.objects.active = outfit
    bpy.ops.object.mode_set(mode='OBJECT')
    for v in outfit.data.vertices:
        wc = outfit.matrix_world @ v.co
        v.select = wc.z > 1.45
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.delete(type='VERT')
    bpy.ops.object.mode_set(mode='OBJECT')
    return outfit


# ---------------------------------------------------------------------------
# Shape keys (visemes / blink / expressions)
# ---------------------------------------------------------------------------

def add_shape_key(obj, name):
    if not obj.data.shape_keys:
        obj.shape_key_add(name='Basis', from_mix=False)
    sk = obj.shape_key_add(name=name, from_mix=False)
    return sk


def displace_region(obj, sk, center, radius, delta):
    """Move vertices of shape key `sk` within `radius` of `center` by `delta` (falloff)."""
    mesh = obj.data
    coords = [v.co for v in mesh.vertices]
    for i, v in enumerate(mesh.vertices):
        wc = obj.matrix_world @ v.co
        d = (wc - center).length
        if d < radius:
            w = 1.0 - (d / radius)
            w = w * w
            sk.data[i].co = coords[i] + delta * w


def build_shape_keys(body_obj):
    # Head region center in world space (object at origin).
    head_c = mathutils.Vector((0, 0, 1.60))
    jaw = add_shape_key(body_obj, "jaw_open")
    displace_region(body_obj, jaw, mathutils.Vector((0, -0.06, 1.48)), 0.12, mathutils.Vector((0, -0.04, 0)))
    blink_l = add_shape_key(body_obj, "blink_L")
    displace_region(body_obj, blink_l, mathutils.Vector((-0.035, -0.09, 1.58)), 0.05, mathutils.Vector((0, -0.02, 0)))
    blink_r = add_shape_key(body_obj, "blink_R")
    displace_region(body_obj, blink_r, mathutils.Vector((0.035, -0.09, 1.58)), 0.05, mathutils.Vector((0, -0.02, 0)))
    smile = add_shape_key(body_obj, "smile")
    displace_region(body_obj, smile, mathutils.Vector((0, -0.08, 1.48)), 0.10, mathutils.Vector((0, 0.025, 0)))
    frown = add_shape_key(body_obj, "frown")
    displace_region(body_obj, frown, mathutils.Vector((0, -0.08, 1.48)), 0.10, mathutils.Vector((0, -0.02, 0)))
    brow = add_shape_key(body_obj, "brow_raise")
    displace_region(body_obj, brow, mathutils.Vector((0, -0.08, 1.63)), 0.08, mathutils.Vector((0, 0, 0.02)))


# ---------------------------------------------------------------------------
# Materials
# ---------------------------------------------------------------------------

def make_material(name, color, metallic=0.0, roughness=0.6):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
    return mat


def assign_material(obj, mat):
    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)


def build_materials(body_obj, face_objs, hair_obj, outfit_obj):
    skin = make_material("Skin", (0.55, 0.40, 0.62), 0.0, 0.5)      # fair violet skin
    outfit_mat = make_material("Outfit", (0.10, 0.06, 0.16), 0.1, 0.4)  # violet-black bodysuit
    hair_mat = make_material("Hair", (0.08, 0.04, 0.14), 0.0, 0.35)    # near-black violet hair
    eye_white = make_material("EyeWhite", (0.95, 0.95, 0.92), 0.0, 0.2)
    iris_mat = make_material("Iris", (0.15, 0.70, 0.95), 0.0, 0.15)    # cyan eyes
    pupil_mat = make_material("Pupil", (0.02, 0.02, 0.05), 0.0, 0.1)
    dark = make_material("Dark", (0.05, 0.03, 0.08), 0.0, 0.4)         # brows/mouth

    assign_material(body_obj, skin)
    assign_material(outfit_obj, outfit_mat)
    assign_material(hair_obj, hair_mat)
    for o in face_objs:
        if o.name.startswith("EyeWhite"):
            assign_material(o, eye_white)
        elif o.name.startswith("Iris"):
            assign_material(o, iris_mat)
        elif o.name.startswith("Pupil"):
            assign_material(o, pupil_mat)
        else:
            assign_material(o, dark)


# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

def export(arm_obj, body_obj):
    if not OUT_DIR:
        return
    os.makedirs(OUT_DIR, exist_ok=True)
    blend_path = os.path.join(OUT_DIR, "violet.blend")
    glb_path = os.path.join(OUT_DIR, "violet.glb")
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format='GLB',
        use_selection=False,
        export_apply=False,
        export_animations=False,
    )
    print("EXPORTED blend=%s glb=%s" % (blend_path, glb_path))


def main():
    reset_scene()
    arm_obj = build_armature()
    body_obj = build_body(arm_obj)
    face_objs = build_face(arm_obj)
    hair_obj = build_hair(arm_obj)
    outfit_obj = build_outfit(body_obj, arm_obj)
    build_shape_keys(body_obj)
    build_materials(body_obj, face_objs, hair_obj, outfit_obj)
    export(arm_obj, body_obj)
    print("DONE")


if __name__ == "__main__":
    main()
