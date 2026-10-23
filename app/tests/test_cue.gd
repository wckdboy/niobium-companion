extends SceneTree
## PerformanceCue tests: clamping, unknown-value fallback, schema validation, expiry.


static func run(f: TestFramework) -> void:
	# Clamp intensity and duration.
	var c := PerformanceCue.from_dict({"schema": 1, "intensity": 2.5, "duration_ms": 999999})
	f.check_eq(c.intensity, 1.0, "intensity clamped to 1")
	f.check_eq(c.duration_ms, PerformanceCue.MAX_DURATION_MS, "duration clamped to max")

	# Unknown expression/gesture fall back to first (safe) value.
	var c2 := PerformanceCue.from_dict({"schema": 1, "expression": "evil", "gesture": "spin_forever", "attention": "void"})
	f.check_eq(c2.expression, "neutral", "unknown expression -> neutral")
	f.check_eq(c2.gesture, "none", "unknown gesture -> none")
	f.check_eq(c2.attention, "user", "unknown attention -> user")

	# Invalid schema is rejected outright.
	var c3 := PerformanceCue.from_dict({"schema": 99})
	f.check_true(c3.is_invalid(), "wrong schema is invalid")

	# Default cue is valid.
	var c4 := PerformanceCue.from_dict({})
	f.check_false(c4.is_invalid(), "default cue valid")
	f.check_eq(c4.schema, 1, "default schema 1")

	# Expiry by duration.
	var c5 := PerformanceCue.from_dict({"schema": 1, "duration_ms": 1000})
	f.check_false(c5.is_expired(0, 500), "not expired before duration")
	f.check_true(c5.is_expired(0, 1500), "expired after duration")

	# Staleness by age.
	var c6 := PerformanceCue.from_dict({"schema": 1, "issued_at_ms": 1000})
	f.check_true(c6.is_stale(1000 + PerformanceCue.MAX_AGE_MS + 1), "stale after max age")
	f.check_false(c6.is_stale(1000), "not stale immediately")


func _initialize() -> void:
	var f := TestFramework.new()
	run(f)
	quit(f.report("test_cue"))
