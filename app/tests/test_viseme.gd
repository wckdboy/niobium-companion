extends SceneTree
## Viseme timeline tests: sample-clock -> morph weights, interpolation, empty state.


static func run(f: TestFramework) -> void:
	var t := VisemeTimeline.new()
	t.set_profile(VisemeProfile.default_profile())

	# Empty timeline.
	f.check_eq(t.weights_at(0), {}, "empty timeline returns empty weights")

	var seg := SpeechSegment.new()
	seg.sample_rate = 24000
	seg.start_sample = 0
	seg.visemes = [
		{"time_ms": 0, "viseme": "A", "weight": 1.0},
		{"time_ms": 100, "viseme": "sil", "weight": 1.0},
	]
	t.add_segment(seg)

	# At start: full jaw open.
	var w0 := t.weights_at(0)
	f.check_near(float(w0.get("jaw_open", 0.0)), 1.0, 0.001, "jaw open at t0")

	# At end keyframe: silent (jaw closed).
	var w1 := t.weights_at(2400)  # 100ms * 24k
	f.check_near(float(w1.get("jaw_open", 0.0)), 0.0, 0.001, "jaw closed at sil")

	# Midway: linear interpolation ~0.5.
	var wm := t.weights_at(1200)
	f.check_near(float(wm.get("jaw_open", 0.0)), 0.5, 0.01, "interpolated halfway")

	# After last keyframe: stays at last.
	var we := t.weights_at(10000)
	f.check_near(float(we.get("jaw_open", 0.0)), 0.0, 0.001, "after last keyframe stays closed")


func _initialize() -> void:
	var f := TestFramework.new()
	run(f)
	quit(f.report("test_viseme"))
