class_name SegmentSequencer
extends RefCounted
## Orders synthesized speech segments by `seq` (not arrival order), assigns contiguous
## `start_sample` positions on the output clock, and is the gate through which every segment
## must pass before playback. Pure and unit-testable. The sample clock is the sync authority.

var _sample_rate := 24000
var _clock := 0
var _pending: Array = []
var _next_seq := 0


func set_sample_rate(sr: int) -> void:
	_sample_rate = sr


func current_clock() -> int:
	return _clock


func reset() -> void:
	_clock = 0
	_pending = []
	_next_seq = 0


## Submit a segment (any arrival order). Returns segments that are now contiguous and ready to
## play, with `start_sample` assigned. Stale/duplicate seq values are dropped.
func submit(segment: SpeechSegment) -> Array:
	if segment.seq < _next_seq:
		return []
	_pending.append(segment)
	_pending.sort_custom(_by_seq)
	var ready: Array = []
	while not _pending.is_empty() and _pending[0].seq == _next_seq:
		var seg: SpeechSegment = _pending.pop_front()
		seg.start_sample = _clock
		_clock += seg.duration_samples
		_next_seq += 1
		ready.append(seg)
	return ready


## True when a segment with the given seq has already been consumed (stale/duplicate).
func already_consumed(seq: int) -> bool:
	return seq < _next_seq


func pending_count() -> int:
	return _pending.size()


static func _by_seq(a: SpeechSegment, b: SpeechSegment) -> bool:
	return a.seq < b.seq
