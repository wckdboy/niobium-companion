class_name AnimationDirector
extends RefCounted
## Layered animation controller (brief §6). Layers:
##   A base idle (breathing, blink)  B attention (gaze)  C expression  D speech visemes
##   E gesture  F secondary (not applicable to the primitive rig; documented)
## Ownership: each morph channel has a single owner, so expression + blink + speech compose
## without overdriving. Bone transforms have a single owner per bone (head controller combines
## gaze + gesture into one pose). Morph composition is pure and unit-tested; bone application
## is device-verified.

const EXPRESSION_MORPHS := {
	"neutral": {},
	"curious": {"brow_raise": 0.6},
	"thinking": {"brow_raise": 0.3},
	"amused": {"smile": 0.7},
	"concerned": {"frown": 0.6, "brow_raise": 0.3},
	"celebratory": {"smile": 0.9, "brow_raise": 0.4},
	"greeting": {"smile": 0.5},
	"attentive": {"brow_raise": 0.2},
	"relaxed": {"smile": 0.2},
}

const GESTURES := {
	"small_nod": {"duration_ms": 600, "head_pitch_deg": -8.0},
	"small_head_tilt": {"duration_ms": 700, "head_roll_deg": 8.0},
	"head_tilt": {"duration_ms": 900, "head_roll_deg": 12.0, "head_yaw_deg": 6.0},
	"wave": {"duration_ms": 1000, "arm_raise_deg": 70.0},
	"explain_hands": {"duration_ms": 1400, "arm_raise_deg": 40.0},
	"shrug": {"duration_ms": 800, "arm_raise_deg": 20.0},
	"lean_in": {"duration_ms": 900, "head_pitch_deg": 6.0},
	"lean_back": {"duration_ms": 900, "head_pitch_deg": -4.0},
}

const EXPRESSION_FADE := 6.0     # per second toward target
const BLINK_MIN_MS := 2000
const BLINK_MAX_MS := 6000
const BLINK_HALF_MS := 80        # closed duration
const BREATH_RATE := 0.22        # Hz
const BREATH_AMP_DEG := 1.6

var _time := 0.0
var _expression := "neutral"
var _expression_target := "neutral"
var _expression_weight := 0.0     # 0..1, eased toward 1 when a non-neutral target is set

var _visemes: Dictionary = {}     # speech-layer morph weights (set each frame)

var _blink_value := 0.0           # 0 open, 1 closed
var _next_blink := 3.0
var _blink_t := 0.0

var _gesture := "none"
var _gesture_start := 0.0
var _gesture_envelope := 0.0


func reset() -> void:
	_time = 0.0
	_expression = "neutral"
	_expression_target = "neutral"
	_expression_weight = 0.0
	_visemes = {}
	_blink_value = 0.0
	_next_blink = 3.0
	_gesture = "none"
	_gesture_envelope = 0.0


func set_expression(name: String) -> void:
	if EXPRESSION_MORPHS.has(name):
		_expression_target = name


func set_expression_weight(w: float) -> void:
	_expression_weight = clampf(w, 0.0, 1.0)


## Drive from the viseme timeline each frame (speech layer).
func set_viseme_weights(weights: Dictionary) -> void:
	_visemes = weights


func play_gesture(name: String) -> void:
	if GESTURES.has(name):
		_gesture = name
		_gesture_start = _time
		_gesture_envelope = 0.0


func current_gesture() -> String:
	return _gesture if _gesture_active() else "none"


func _gesture_active() -> bool:
	if _gesture == "none" or not GESTURES.has(_gesture):
		return false
	var dur := float(GESTURES[_gesture]["duration_ms"]) / 1000.0
	return (_time - _gesture_start) < dur


func advance(delta: float) -> void:
	_time += delta
	# Expression weight eases toward 1 while a non-neutral expression is targeted, else 0.
	var target_w := 1.0 if _expression_target != "neutral" else 0.0
	_expression_weight = move_toward(_expression_weight, target_w, EXPRESSION_FADE * delta)
	if is_equal_approx(_expression_weight, 0.0):
		_expression = "neutral"
	else:
		_expression = _expression_target
	# Blink scheduling.
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink_t = 0.0
		_next_blink = randf_range(BLINK_MIN_MS, BLINK_MAX_MS) / 1000.0
	if _blink_t < BLINK_HALF_MS / 1000.0:
		_blink_t += delta
		var k := _blink_t / (BLINK_HALF_MS / 1000.0)
		_blink_value = 1.0 - abs(1.0 - 2.0 * k)  # 0->1->0 over the blink
	else:
		_blink_value = 0.0


## Pure morph composition. Returns final per-channel weights in [0, 1].
func compute_morphs() -> Dictionary:
	var out: Dictionary = {}
	# Blink (owner: blink_L/R).
	out["blink_L"] = _blink_value
	out["blink_R"] = _blink_value
	# Expression (owner: smile/frown/brow_raise).
	var expr: Dictionary = EXPRESSION_MORPHS.get(_expression, {})
	for m in expr:
		out[m] = float(expr[m]) * _expression_weight
	# Speech (owner: jaw/lips channels).
	for m in _visemes:
		out[m] = float(_visemes[m])
	# Clamp everything to [0,1]; no channel is double-owned so this is a safety net only.
	for m in out:
		out[m] = clampf(out[m], 0.0, 1.0)
	return out


func breathing_phase() -> float:
	return sin(_time * BREATH_RATE * TAU)


func breathing_amplitude_deg() -> float:
	return BREATH_AMP_DEG


## Head bone delta (deg) from gesture + gaze, combined into one owner. Device-verified.
func gesture_bone_deltas() -> Dictionary:
	if not _gesture_active():
		return {}
	var g: Dictionary = GESTURES.get(_gesture, {})
	var dur := float(g.get("duration_ms", 1000)) / 1000.0
	var t := (_time - _gesture_start) / dur
	_gesture_envelope = sin(clampf(t, 0.0, 1.0) * PI)  # 0 -> 1 -> 0
	var out := {}
	if g.has("head_pitch_deg"):
		out["head_pitch_deg"] = float(g["head_pitch_deg"]) * _gesture_envelope
	if g.has("head_yaw_deg"):
		out["head_yaw_deg"] = float(g["head_yaw_deg"]) * _gesture_envelope
	if g.has("head_roll_deg"):
		out["head_roll_deg"] = float(g["head_roll_deg"]) * _gesture_envelope
	if g.has("arm_raise_deg"):
		out["arm_raise_deg"] = float(g["arm_raise_deg"]) * _gesture_envelope
	return out
