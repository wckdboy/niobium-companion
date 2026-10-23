extends SceneTree
## AnimationDirector tests: morph composition stays in [0,1] (no overdrive), expression fade,
## blink bounds, gesture lifecycle returning to neutral.


static func run(f: TestFramework) -> void:
	var d := AnimationDirector.new()

	# Max speech + expression + blink must not overdrive any channel.
	d.set_viseme_weights({"jaw_open": 1.0, "lips_round": 1.0})
	d.set_expression("celebratory")  # smile 0.9, brow_raise 0.4
	for i in 20:
		d.advance(0.1)  # fade expression weight to ~1
	var morphs := d.compute_morphs()
	for m in morphs:
		f.check_true(morphs[m] >= 0.0 and morphs[m] <= 1.0, "morph %s within [0,1]" % m)

	# Blink channel exists and is bounded.
	f.check_true(morphs.has("blink_L") and morphs.has("blink_R"), "blink channels present")
	f.check_near(float(morphs["blink_L"]), float(morphs["blink_R"]), 0.0001, "blink L==R")

	# Expression drives smile at ~0.9 when fully faded.
	f.check_near(float(morphs.get("smile", 0.0)), 0.9, 0.05, "celebratory smile")

	# Gesture lifecycle.
	d.reset()
	d.play_gesture("small_nod")
	f.check_eq(d.current_gesture(), "small_nod", "gesture active after play")
	var deltas := d.gesture_bone_deltas()
	f.check_true(deltas.has("head_pitch_deg"), "nod has head pitch")
	for i in 200:
		d.advance(0.01)  # > 600ms
	f.check_eq(d.current_gesture(), "none", "gesture returns to neutral")

	# Unknown gesture ignored.
	d.reset()
	d.play_gesture("nonexistent")
	f.check_eq(d.current_gesture(), "none", "unknown gesture ignored")


func _initialize() -> void:
	var f := TestFramework.new()
	run(f)
	quit(f.report("test_animation"))
