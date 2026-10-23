extends SceneTree
## Verify the Blender-authored glTF imports with the expected bones + face morphs.


static func _find(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for c in node.get_children():
		var r := _find(c, type_name)
		if r != null:
			return r
	return null


static func run(f: TestFramework) -> void:
	var scene: PackedScene = load("res://assets/characters/violet.glb")
	f.check_ne(scene, null, "violet.glb loads")
	if scene == null:
		return
	var inst := scene.instantiate()
	f.check_ne(inst, null, "instantiates")
	var skel: Skeleton3D = _find(inst, "Skeleton3D")
	f.check_ne(skel, null, "Skeleton3D found")
	if skel != null:
		# Core RigProfile bones must all be present.
		for b in RigProfile.HUMAN_BONES:
			f.check_true(skel.find_bone(b) >= 0, "core bone present: " + b)
		# Fingers present (extra).
		f.check_true(skel.find_bone("Index.L.01") >= 0, "finger bone present")
		f.check_true(skel.find_bone("Pinky.R.03") >= 0, "finger bone present")
		f.check_true(skel.get_bone_count() >= RigProfile.HUMAN_BONES.size(), "bone count >= core")

	# Find a mesh with blend shapes (face morphs).
	var morph_mesh: MeshInstance3D = null
	var queue: Array = [inst]
	while not queue.is_empty() and morph_mesh == null:
		var n: Node = queue.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			if (n as MeshInstance3D).mesh.get_blend_shape_count() > 0:
				morph_mesh = n
		for c in n.get_children():
			queue.append(c)
	f.check_ne(morph_mesh, null, "mesh with blend shapes found")
	if morph_mesh != null:
		var count: int = morph_mesh.mesh.get_blend_shape_count()
		f.check_true(count >= 6, ">=6 face morphs (got %d)" % count)
		# print all blend shape names for diagnostics
		var names: Array = []
		for i in count:
			names.append(morph_mesh.mesh.get_blend_shape_name(i))
		print("blend shapes: ", names)

	inst.free()


func _initialize() -> void:
	var f := TestFramework.new()
	run(f)
	quit(f.report("test_gltf"))
