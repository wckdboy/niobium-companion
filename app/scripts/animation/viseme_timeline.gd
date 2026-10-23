class_name VisemeTimeline
extends RefCounted
## Maps an absolute playback sample clock to morph-channel weights. Keyframes are sorted by
## sample; weights are linearly interpolated between consecutive keyframes. This is pure and
## unit-testable; the AudioPlayback sample clock drives it at runtime.

var _profile: VisemeProfile
var _keyframes: Array = []   # sorted [{sample:int, viseme:String, weight:float}]


func set_profile(profile: VisemeProfile) -> void:
	_profile = profile


func clear() -> void:
	_keyframes = []


## Absorb a segment's viseme plan. Segment visemes are {time_ms, viseme, weight} relative to
## the segment start; converted to absolute samples using the segment's start_sample.
func add_segment(segment: SpeechSegment) -> void:
	var sr := segment.sample_rate
	if sr <= 0:
		return
	for v in segment.visemes:
		if typeof(v) != TYPE_DICTIONARY:
			continue
		var rel_ms := int(v.get("time_ms", 0))
		var sample := segment.start_sample + int(float(rel_ms) * float(sr) / 1000.0)
		_keyframes.append({
			"sample": sample,
			"viseme": str(v.get("viseme", "sil")),
			"weight": float(v.get("weight", 1.0)),
		})
	_keyframes.sort_custom(_sort_by_sample)


func weights_at(sample: int) -> Dictionary:
	if _profile == null or _keyframes.is_empty():
		return {}
	# Find the segment [i, i+1] containing `sample`.
	var i := -1
	for k in range(_keyframes.size()):
		if _keyframes[k]["sample"] <= sample:
			i = k
		else:
			break
	if i < 0:
		return {}
	var cur: Dictionary = _keyframes[i]
	var next: Dictionary = _keyframes[i + 1] if i + 1 < _keyframes.size() else {}
	if next.is_empty():
		return _scaled(cur)
	var cur_s: int = cur["sample"]
	var next_s: int = next["sample"]
	var span: int = next_s - cur_s
	if span <= 0:
		return _scaled(next)
	var t := clampf(float(sample - cur_s) / float(span), 0.0, 1.0)
	return _blend(_scaled(cur), _scaled(next), t)


func _scaled(kf: Dictionary) -> Dictionary:
	var w := _profile.weights(kf["viseme"])
	var out := {}
	for m in w:
		out[m] = float(w[m]) * float(kf["weight"])
	return out


static func _blend(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var out := {}
	for m in a:
		out[m] = float(a[m]) * (1.0 - t)
	for m in b:
		out[m] = out.get(m, 0.0) + float(b[m]) * t
	return out


static func _sort_by_sample(a: Dictionary, b: Dictionary) -> bool:
	return int(a["sample"]) < int(b["sample"])
