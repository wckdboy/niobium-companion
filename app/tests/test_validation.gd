extends SceneTree
## ValidationReport + RigProfile tests: missing bones are errors, missing morphs warnings,
## budget violations, roundtrip serialization.


static func run(f: TestFramework) -> void:
	var profile := RigProfile.new()
	profile.bones = ["Hips", "Head", "Neck"]
	profile.morphs = ["jaw_open", "blink_L"]

	# Missing bone -> error (fatal).
	var r := ValidationReport.validate(profile, ["Hips", "Neck"], ["jaw_open", "blink_L"])
	f.check_false(r.ok(), "missing bone fails validation")
	f.check_eq(r.errors.size(), 1, "one error for missing Head")

	# Missing morph -> warning (recoverable).
	var r2 := ValidationReport.validate(profile, ["Hips", "Head", "Neck"], ["jaw_open"])
	f.check_true(r2.ok(), "missing morph is not fatal")
	f.check_eq(r2.warnings.size(), 1, "one warning for missing blink_L")

	# Budget violation.
	var r3 := ValidationReport.validate(
		profile, ["Hips", "Head", "Neck"], ["jaw_open", "blink_L"],
		{"max_vertices": 10000, "vertex_count": 50000})
	f.check_false(r3.ok(), "vertex budget exceeded fails")
	f.check_true(r3.errors[0].contains("vertex"), "budget error mentions vertex")

	# Clean case passes.
	var r4 := ValidationReport.validate(profile, ["Hips", "Head", "Neck"], ["jaw_open", "blink_L"])
	f.check_true(r4.ok(), "valid avatar passes")

	# RigProfile roundtrip preserves viseme map + rights flag.
	profile.rights_cleared = true
	profile.viseme_profile = VisemeProfile.default_profile()
	var d := profile.to_dict()
	var back := RigProfile.from_dict(d)
	f.check_true(back.rights_cleared, "rights flag preserved")
	f.check_eq(back.bones.size(), 3, "bones preserved")
	f.check_near(float(back.viseme_profile.weights("A")["jaw_open"]), 1.0, 0.001, "viseme map preserved")


func _initialize() -> void:
	var f := TestFramework.new()
	run(f)
	quit(f.report("test_validation"))
