class_name VisemeProfile
extends RefCounted
## Maps viseme ids to morph-channel weights for the current rig. A RigProfile supplies its
## own morph channel names; this profile is the speech-facing map. Unknown morph channels are
## ignored by the rig (never double-driven).

const VISEMES := ["sil", "A", "E", "I", "O", "U", "F", "M"]

var _map: Dictionary = {}   # viseme -> { morph_channel -> weight }


func set_weights(viseme: String, weights: Dictionary) -> void:
	_map[viseme] = weights


func weights(viseme: String) -> Dictionary:
	if _map.has(viseme):
		return _map[viseme]
	return {}


func morphs() -> Array:
	var out := {}
	for v in _map:
		for m in _map[v]:
			out[m] = true
	return out.keys()


## A generic default mapping suitable for a humanoid with jaw/lips morphs.
static func default_profile() -> VisemeProfile:
	var p := VisemeProfile.new()
	p.set_weights("sil", {})
	p.set_weights("A", {"jaw_open": 1.0})
	p.set_weights("E", {"jaw_open": 0.5, "lips_wide": 0.6})
	p.set_weights("I", {"jaw_open": 0.3, "lips_wide": 1.0})
	p.set_weights("O", {"jaw_open": 0.6, "lips_round": 0.8})
	p.set_weights("U", {"jaw_open": 0.3, "lips_round": 1.0})
	p.set_weights("F", {"jaw_open": 0.15, "lips_f": 0.8})
	p.set_weights("M", {"jaw_open": 0.1, "lips_close": 0.8})
	return p
