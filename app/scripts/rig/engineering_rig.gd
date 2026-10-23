class_name EngineeringRig
extends Node3D
## Procedural engineering rig (TEMPORARY fixture, NOT final art — see docs/ASSETS.md).
## Builds a humanoid Skeleton3D with primitive-mesh body parts attached via BoneAttachment3D,
## a head ArrayMesh with face blend shapes (jaw/lips/brows/expressions), independent eye bones,
## and named camera anchors. It is rigged and animatable so the animation/speech/camera systems
## can be exercised, but it is never claimed as the finished character.

const RIG_ID := "engineering_rig_v1"

var skeleton: Skeleton3D
var head_mesh: MeshInstance3D
var eye_l: Node3D
var eye_r: Node3D
var camera_anchors: Dictionary = {}
var _bone_index: Dictionary = {}
var _head_blend_shapes: Array = []


func build() -> void:
	_build_skeleton()
	_build_body()
	_build_head()
	_build_eyes()
	_build_cameras()


func bone_names() -> Array:
	return RigProfile.HUMAN_BONES


func morph_channels() -> Array:
	# Channels this rig exposes (blink handled via eye scale; others via head blend shapes).
	var out := _head_blend_shapes.duplicate()
	out.append_array(["blink_L", "blink_R"])
	return out


## Single morph sink used by the AnimationDirector.
func set_morph(channel: String, weight: float) -> void:
	var w := clampf(weight, 0.0, 1.0)
	if channel == "blink_L" and eye_l != null:
		eye_l.scale = Vector3(1.0, 1.0 - w * 0.85, 1.0)
	elif channel == "blink_R" and eye_r != null:
		eye_r.scale = Vector3(1.0, 1.0 - w * 0.85, 1.0)
	elif head_mesh != null and _head_blend_shapes.has(channel):
		head_mesh.set("blend_shapes/%s" % channel, w)


## Bone pose helpers for the AnimationDirector (single owner per bone).
func set_bone_rotation(bone: String, axis: Vector3, angle_rad: float) -> void:
	if not _bone_index.has(bone):
		return
	var idx: int = _bone_index[bone]
	skeleton.set_bone_pose_rotation(idx, Quaternion(axis.normalized(), angle_rad))


func set_bone_rotation_deg(bone: String, axis: Vector3, angle_deg: float) -> void:
	set_bone_rotation(bone, axis, deg_to_rad(angle_deg))


## Set an absolute bone pose rotation (single owner). Composes yaw*pitch*roll before calling.
func set_bone_pose_rotation_quat(bone: String, q: Quaternion) -> void:
	if _bone_index.has(bone):
		skeleton.set_bone_pose_rotation(int(_bone_index[bone]), q)


func reset_pose() -> void:
	# Reset every bone's pose to its rest pose (identity pose would collapse the skeleton).
	skeleton.reset_bone_poses()


func _build_skeleton() -> void:
	skeleton = Skeleton3D.new()
	skeleton.set_name("Skeleton3D")
	add_child(skeleton)
	_add_bone("Hips", Vector3(0, 0.95, 0), "")
	_add_bone("Spine", Vector3(0, 0.18, 0), "Hips")
	_add_bone("Chest", Vector3(0, 0.22, 0), "Spine")
	_add_bone("Neck", Vector3(0, 0.18, 0), "Chest")
	_add_bone("Head", Vector3(0, 0.16, 0), "Neck")
	_add_bone("Shoulder.L", Vector3(-0.14, 0.12, 0), "Chest")
	_add_bone("UpperArm.L", Vector3(-0.07, -0.30, 0), "Shoulder.L")
	_add_bone("LowerArm.L", Vector3(0, -0.26, 0), "UpperArm.L")
	_add_bone("Hand.L", Vector3(0, -0.22, 0), "LowerArm.L")
	_add_bone("Shoulder.R", Vector3(0.14, 0.12, 0), "Chest")
	_add_bone("UpperArm.R", Vector3(0.07, -0.30, 0), "Shoulder.R")
	_add_bone("LowerArm.R", Vector3(0, -0.26, 0), "UpperArm.R")
	_add_bone("Hand.R", Vector3(0, -0.22, 0), "LowerArm.R")
	_add_bone("UpperLeg.L", Vector3(-0.10, -0.06, 0), "Hips")
	_add_bone("LowerLeg.L", Vector3(0, -0.40, 0), "UpperLeg.L")
	_add_bone("Foot.L", Vector3(0, -0.38, 0), "LowerLeg.L")
	_add_bone("UpperLeg.R", Vector3(0.10, -0.06, 0), "Hips")
	_add_bone("LowerLeg.R", Vector3(0, -0.40, 0), "UpperLeg.R")
	_add_bone("Foot.R", Vector3(0, -0.38, 0), "LowerLeg.R")
	_add_bone("Eye.L", Vector3(-0.045, 0.10, 0.115), "Head")
	_add_bone("Eye.R", Vector3(0.045, 0.10, 0.115), "Head")


func _add_bone(name: String, rest: Vector3, parent: String) -> void:
	var idx := skeleton.get_bone_count()
	skeleton.add_bone(name)
	skeleton.set_bone_rest(idx, Transform3D(Basis.IDENTITY, rest))
	if parent != "":
		skeleton.set_bone_parent(idx, int(_bone_index[parent]))
	_bone_index[name] = idx


func _build_body() -> void:
	var mat_body := _material(Color(0.20, 0.10, 0.30), 0.55)
	# Torso (capsule spanning spine/chest).
	_attach_capsule("Chest", Vector3(0, -0.05, 0), 0.20, 0.55, mat_body)
	# Pelvis.
	_attach_capsule("Hips", Vector3(0, 0.02, 0), 0.17, 0.28, mat_body)
	# Arms.
	_attach_capsule("UpperArm.L", Vector3(0, -0.14, 0), 0.06, 0.30, mat_body)
	_attach_capsule("LowerArm.L", Vector3(0, -0.12, 0), 0.05, 0.26, mat_body)
	_attach_capsule("UpperArm.R", Vector3(0, -0.14, 0), 0.06, 0.30, mat_body)
	_attach_capsule("LowerArm.R", Vector3(0, -0.12, 0), 0.05, 0.26, mat_body)
	# Legs.
	_attach_capsule("UpperLeg.L", Vector3(0, -0.20, 0), 0.07, 0.40, mat_body)
	_attach_capsule("LowerLeg.L", Vector3(0, -0.18, 0), 0.055, 0.36, mat_body)
	_attach_capsule("UpperLeg.R", Vector3(0, -0.20, 0), 0.07, 0.40, mat_body)
	_attach_capsule("LowerLeg.R", Vector3(0, -0.18, 0), 0.055, 0.36, mat_body)


func _build_head() -> void:
	head_mesh = MeshInstance3D.new()
	head_mesh.set_name("Head")
	head_mesh.mesh = _build_head_mesh(0.14)
	head_mesh.material_override = _material(Color(0.24, 0.14, 0.34), 0.5)
	var attach := _attach_node("Head", head_mesh, Transform3D(Basis.IDENTITY, Vector3(0, 0, 0)))


func _build_eyes() -> void:
	var mat_eye_white := _material(Color(0.95, 0.95, 0.92), 0.2)
	var mat_iris := _material(Color(0.20, 0.55, 0.95), 0.1)
	eye_l = _eye("Eye.L", mat_eye_white, mat_iris)
	eye_r = _eye("Eye.R", mat_eye_white, mat_iris)


func _eye(bone: String, white: Material, iris: Material) -> Node3D:
	var group := Node3D.new()
	group.set_name("Eye")
	var ball := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.028
	sm.height = 0.056
	ball.mesh = sm
	ball.material_override = white
	group.add_child(ball)
	var pupil := MeshInstance3D.new()
	var pm := SphereMesh.new()
	pm.radius = 0.012
	pm.height = 0.024
	pupil.mesh = pm
	pupil.material_override = iris
	pupil.position = Vector3(0, 0, 0.02)
	group.add_child(pupil)
	_attach_node(bone, group, Transform3D.IDENTITY)
	return group


func _build_cameras() -> void:
	# Named anchors; the camera rig moves to these. Character faces +Z.
	var defs := {
		"portrait": Transform3D(Basis.IDENTITY, Vector3(0, 1.66, 0.55)),
		"bust": Transform3D(Basis.IDENTITY, Vector3(0, 1.45, 0.95)),
		"waist": Transform3D(Basis.IDENTITY, Vector3(0, 1.05, 1.55)),
		"full": Transform3D(Basis.IDENTITY, Vector3(0, 0.85, 2.1)),
	}
	for name in defs:
		var m := Marker3D.new()
		m.set_name(name)
		m.transform = defs[name]
		add_child(m)
		camera_anchors[name] = m


func _attach_capsule(bone: String, offset: Vector3, radius: float, height: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = radius
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat
	_attach_node(bone, mi, Transform3D(Basis.IDENTITY, offset))


func _attach_node(bone: String, node: Node3D, local: Transform3D) -> BoneAttachment3D:
	var ba := BoneAttachment3D.new()
	ba.bone_name = bone
	ba.bone_idx = -1
	skeleton.add_child(ba)
	ba.add_child(node)
	node.transform = local
	return ba


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = 0.0
	return m


## Build a UV-sphere ArrayMesh with face blend shapes. Engineering-fixture quality: region-
## weighted vertex displacements, not a sculpted face.
func _build_head_mesh(radius: float) -> ArrayMesh:
	var lat := 28
	var lon := 40
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in lat + 1:
		var theta := PI * float(i) / float(lat)
		var y := cos(theta) * radius
		var r := sin(theta) * radius
		for j in lon + 1:
			var phi := TAU * float(j) / float(lon)
			var x := r * sin(phi)
			var z := r * cos(phi)
			verts.append(Vector3(x, y, z))
			norms.append(Vector3(x, y, z).normalized())
			uvs.append(Vector2(float(j) / float(lon), float(i) / float(lat)))
	for i in lat:
		for j in lon:
			var a := i * (lon + 1) + j
			var b := a + lon + 1
			indices.append_array([a, b, a + 1, b, b + 1, a + 1])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TANGENT] = _zero_float(verts.size() * 4)

	var mesh := ArrayMesh.new()
	var shapes: Array = [
		["jaw_open", _jaw_open_offsets(verts, radius)],
		["smile", _smile_offsets(verts, radius)],
		["frown", _frown_offsets(verts, radius)],
		["brow_raise", _brow_offsets(verts, radius)],
		["lips_wide", _lips_wide_offsets(verts, radius)],
		["lips_round", _lips_round_offsets(verts, radius)],
		["lips_f", _lips_f_offsets(verts, radius)],
		["lips_close", _lips_close_offsets(verts, radius)],
	]
	_head_blend_shapes = []
	var blend_shape_arrays: Array = []
	var zero_normals := _zero_vec3(verts.size())
	var zero_tangents := _zero_float(verts.size() * 4)
	for s in shapes:
		mesh.add_blend_shape(s[0])
		_head_blend_shapes.append(s[0])
		blend_shape_arrays.append([s[1], zero_normals, zero_tangents])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, blend_shape_arrays)
	return mesh


func _zero_vec3(count: int) -> PackedVector3Array:
	var z := PackedVector3Array()
	z.resize(count)
	return z


func _zero_float(count: int) -> PackedFloat32Array:
	var z := PackedFloat32Array()
	z.resize(count)
	return z


func _jaw_open_offsets(verts: PackedVector3Array, r: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(verts.size())
	for i in verts.size():
		var v := verts[i]
		var w := _front_lower(v, r)
		out[i] = Vector3(0, -0.12 * r, 0.03 * r) * w
	return out


func _smile_offsets(verts: PackedVector3Array, r: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(verts.size())
	for i in verts.size():
		var v := verts[i]
		var w := _mouth_corner(v, r)
		out[i] = Vector3(signf(v.x) * 0.05 * r, 0.05 * r, -0.02 * r) * w
	return out


func _frown_offsets(verts: PackedVector3Array, r: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(verts.size())
	for i in verts.size():
		var v := verts[i]
		var w := _mouth_corner(v, r)
		out[i] = Vector3(signf(v.x) * 0.04 * r, -0.05 * r, 0.0) * w
	return out


func _brow_offsets(verts: PackedVector3Array, r: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(verts.size())
	for i in verts.size():
		var v := verts[i]
		var w := _brow_region(v, r)
		out[i] = Vector3(0, 0.06 * r, 0.01 * r) * w
	return out


func _lips_wide_offsets(verts: PackedVector3Array, r: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(verts.size())
	for i in verts.size():
		var v := verts[i]
		var w := _mouth_region(v, r)
		out[i] = Vector3(signf(v.x) * 0.04 * r, 0, 0) * w
	return out


func _lips_round_offsets(verts: PackedVector3Array, r: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(verts.size())
	for i in verts.size():
		var v := verts[i]
		var w := _mouth_region(v, r)
		out[i] = Vector3(-signf(v.x) * 0.03 * r, 0, 0.05 * r) * w
	return out


func _lips_f_offsets(verts: PackedVector3Array, r: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(verts.size())
	for i in verts.size():
		var v := verts[i]
		out[i] = Vector3(0, 0, 0.03 * r) * _mouth_region(v, r)
	return out


func _lips_close_offsets(verts: PackedVector3Array, r: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(verts.size())
	for i in verts.size():
		var v := verts[i]
		out[i] = Vector3(0, -0.03 * r, 0) * _mouth_region(v, r)
	return out


func _front_lower(v: Vector3, r: float) -> float:
	var z := clampf((v.z / r + 0.2) / 1.0, 0.0, 1.0)
	var y := clampf(-v.y / r, 0.0, 1.0)
	return z * y


func _mouth_region(v: Vector3, r: float) -> float:
	var z := clampf(v.z / r, 0.0, 1.0)
	var y := clampf(1.0 - abs(v.y / r) / 0.35, 0.0, 1.0)
	return z * y


func _mouth_corner(v: Vector3, r: float) -> float:
	var z := clampf(v.z / r, 0.0, 1.0)
	var x := clampf(abs(v.x / r) / 0.5, 0.0, 1.0)
	var y := clampf(1.0 - abs(v.y / r) / 0.3, 0.0, 1.0)
	return z * x * y


func _brow_region(v: Vector3, r: float) -> float:
	var z := clampf(v.z / r, 0.0, 1.0)
	var y := clampf((v.y / r - 0.2) / 0.5, 0.0, 1.0)
	var x := clampf(1.0 - abs(v.x / r) / 0.6, 0.0, 1.0)
	return z * y * x
