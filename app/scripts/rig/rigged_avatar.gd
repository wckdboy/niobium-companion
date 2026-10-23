class_name RiggedAvatar
extends Node3D
## Loads an authored glTF character and exposes the same interface the CompanionStage expects
## (skeleton, bone pose helpers, morph channels, camera anchors). Replaces the temporary
## EngineeringRig with a real skinned+rigged character produced in Blender (avatars/blender).

var skeleton: Skeleton3D
var morph_mesh: MeshInstance3D
var camera_anchors: Dictionary = {}
var _bone_index: Dictionary = {}
var _morph_names: Dictionary = {}
var source_path: String = ""


func load_avatar(path: String) -> bool:
	source_path = path
	var scene: PackedScene = load(path)
	if scene == null:
		push_error("RiggedAvatar: cannot load " + path)
		return false
	var inst := scene.instantiate()
	add_child(inst)
	skeleton = _find_skeleton(inst)
	if skeleton == null:
		push_error("RiggedAvatar: no Skeleton3D in " + path)
		return false
	_build_bone_index()
	morph_mesh = _find_morph_mesh(inst)
	if morph_mesh != null:
		_build_morph_names()
	_build_cameras()
	reset_pose()
	return true


func bone_names() -> Array:
	return _bone_index.keys()


func morph_channels() -> Array:
	return _morph_names.keys()


## Single morph sink used by the AnimationDirector (speech + blink + expression channels).
func set_morph(channel: String, weight: float) -> void:
	if morph_mesh == null or not _morph_names.has(channel):
		return
	morph_mesh.set("blend_shapes/" + channel, clampf(weight, 0.0, 1.0))


func set_bone_rotation(bone: String, axis: Vector3, angle_rad: float) -> void:
	if not _bone_index.has(bone):
		return
	skeleton.set_bone_pose_rotation(int(_bone_index[bone]), Quaternion(axis.normalized(), angle_rad))


func set_bone_rotation_deg(bone: String, axis: Vector3, angle_deg: float) -> void:
	set_bone_rotation(bone, axis, deg_to_rad(angle_deg))


func set_bone_pose_rotation_quat(bone: String, q: Quaternion) -> void:
	if _bone_index.has(bone):
		skeleton.set_bone_pose_rotation(int(_bone_index[bone]), q)


func reset_pose() -> void:
	if skeleton != null:
		skeleton.reset_bone_poses()


func _build_bone_index() -> void:
	_bone_index = {}
	for i in skeleton.get_bone_count():
		_bone_index[skeleton.get_bone_name(i)] = i


func _build_morph_names() -> void:
	_morph_names = {}
	for i in morph_mesh.mesh.get_blend_shape_count():
		_morph_names[morph_mesh.mesh.get_blend_shape_name(i)] = true


func _build_cameras() -> void:
	# Same anchors as the EngineeringRig, in world space (avatar at origin, ~1.8 units tall).
	var defs := {
		"portrait": Vector3(0, 1.70, 0.55),
		"bust": Vector3(0, 1.45, 0.95),
		"waist": Vector3(0, 1.10, 1.7),
		"full": Vector3(0, 0.95, 2.7),
	}
	for name in defs:
		var m := Marker3D.new()
		m.set_name(name)
		m.position = defs[name]
		add_child(m)
		camera_anchors[name] = m


static func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for c in node.get_children():
		var r := _find_skeleton(c)
		if r != null:
			return r
	return null


static func _find_morph_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null and mi.mesh.get_blend_shape_count() > 0:
			return mi
	for c in node.get_children():
		var r := _find_morph_mesh(c)
		if r != null:
			return r
	return null
