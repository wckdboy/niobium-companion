extends SceneTree
## EngineeringRig tests: the procedural rig builds a complete humanoid skeleton, head blend
## shapes, eyes and camera anchors — headless (no rendering).


static func run(f: TestFramework) -> void:
	var rig := EngineeringRig.new()
	rig.build()

	f.check_eq(rig.skeleton.get_bone_count(), RigProfile.HUMAN_BONES.size(), "all humanoid bones present")
	f.check_eq(rig.bone_names(), RigProfile.HUMAN_BONES, "bone_names matches convention")

	# Morph channels include speech + blink.
	var morphs := rig.morph_channels()
	f.check_true(morphs.has("jaw_open"), "jaw_open morph channel")
	f.check_true(morphs.has("blink_L"), "blink_L channel")
	f.check_true(morphs.has("smile"), "smile channel")

	# Head mesh has the expected blend shapes.
	var count: int = (rig.head_mesh.mesh as ArrayMesh).get_blend_shape_count()
	f.check_true(count >= 6, "head mesh blend shapes built (got %d)" % count)

	# Camera anchors present for all framings.
	for anchor in RigProfile.CAMERA_ANCHORS:
		f.check_true(rig.camera_anchors.has(anchor), "camera anchor %s" % anchor)

	# Bone pose helpers work without error.
	rig.set_bone_rotation_deg("Head", Vector3.UP, 10.0)
	rig.reset_pose()

	rig.free()


func _initialize() -> void:
	var f := TestFramework.new()
	run(f)
	quit(f.report("test_rig"))
