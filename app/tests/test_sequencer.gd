extends SceneTree
## Segment sequencer tests: ordering by seq (not arrival), contiguous sample clock, reset.


static func _seg(seq: int, dur: int) -> SpeechSegment:
	var s := SpeechSegment.new()
	s.id = SpeechSegment.new_id()
	s.seq = seq
	s.sample_rate = 24000
	s.duration_samples = dur
	return s


static func run(f: TestFramework) -> void:
	var q := SegmentSequencer.new()
	q.set_sample_rate(24000)

	# In-order submit: contiguous clock assignment.
	var ready := q.submit(_seg(0, 1000))
	f.check_eq(ready.size(), 1, "seq 0 ready immediately")
	f.check_eq(ready[0].start_sample, 0, "seq 0 starts at 0")

	# Out-of-order: submit seq 1 first, then seq 0.
	q.reset()
	var r0 := q.submit(_seg(1, 500))
	f.check_eq(r0.size(), 0, "seq 1 held until seq 0 arrives")
	var r1 := q.submit(_seg(0, 700))
	f.check_eq(r1.size(), 2, "seq 0 and 1 emitted in order")
	f.check_eq(r1[0].seq, 0, "first emitted is seq 0")
	f.check_eq(r1[1].seq, 1, "second emitted is seq 1")
	f.check_eq(r1[0].start_sample, 0, "seq 0 starts at 0")
	f.check_eq(r1[1].start_sample, 700, "seq 1 starts after seq 0 duration")

	# Duplicate/stale seq is dropped, not re-consumed.
	f.check_true(q.already_consumed(0), "seq 0 already consumed")
	var r2 := q.submit(_seg(0, 999))
	f.check_eq(r2.size(), 0, "duplicate seq 0 dropped")

	# Clock accumulates across submits.
	f.check_eq(q.current_clock(), 1200, "clock accumulated")


func _initialize() -> void:
	var f := TestFramework.new()
	run(f)
	quit(f.report("test_sequencer"))
