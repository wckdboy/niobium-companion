class_name PerformanceCue
extends RefCounted
## A single high-level performance hint from the model or a local cue analyser.
## Schema v1 (brief §6). Cues are validated and clamped; invalid cues are ignored
## without breaking speech, and stale cues expire.

const SCHEMA := 1

const EXPRESSIONS := [
	"neutral", "curious", "thinking", "amused", "concerned",
	"celebratory", "greeting", "attentive", "relaxed",
]

const GESTURES := [
	"none", "small_nod", "small_head_tilt", "head_tilt", "wave",
	"explain_hands", "shrug", "lean_in", "lean_back",
]

const ATTENTION_TARGETS := ["user", "screen", "away", "none"]

const MIN_DURATION_MS := 0
const MAX_DURATION_MS := 20000
const MAX_AGE_MS := 30000  # cues older than this relative to turn start are stale

var schema: int = SCHEMA
var turn_id: String = ""
var segment_id: String = ""
var expression: String = "neutral"
var intensity: float = 0.0
var gesture: String = "none"
var attention: String = "none"
var duration_ms: int = 0
var issued_at_ms: int = 0


static func from_dict(data: Dictionary) -> PerformanceCue:
	var cue := PerformanceCue.new()
	if typeof(data) != TYPE_DICTIONARY:
		return cue
	cue.schema = int(data.get("schema", SCHEMA))
	cue.turn_id = str(data.get("turn_id", ""))
	cue.segment_id = str(data.get("segment_id", ""))
	cue.expression = _pick(EXPRESSIONS, str(data.get("expression", "neutral")))
	cue.gesture = _pick(GESTURES, str(data.get("gesture", "none")))
	cue.attention = _pick(ATTENTION_TARGETS, str(data.get("attention", "none")))
	cue.intensity = clampf(float(data.get("intensity", 0.0)), 0.0, 1.0)
	cue.duration_ms = clampi(int(data.get("duration_ms", 0)), MIN_DURATION_MS, MAX_DURATION_MS)
	cue.issued_at_ms = int(data.get("issued_at_ms", 0))
	return cue


static func _pick(allowed: Array, value: String) -> String:
	if allowed.has(value):
		return value
	return allowed[0]


## Returns true when a cue is malformed enough that it must be dropped entirely.
func is_invalid() -> bool:
	return schema != SCHEMA


func is_stale(now_ms: int) -> bool:
	if issued_at_ms <= 0:
		return false
	return now_ms - issued_at_ms > MAX_AGE_MS


func is_expired(started_at_ms: int, now_ms: int) -> bool:
	if duration_ms <= 0:
		return false
	return now_ms - started_at_ms > duration_ms


func to_dict() -> Dictionary:
	return {
		"schema": schema,
		"turn_id": turn_id,
		"segment_id": segment_id,
		"expression": expression,
		"intensity": intensity,
		"gesture": gesture,
		"attention": attention,
		"duration_ms": duration_ms,
		"issued_at_ms": issued_at_ms,
	}
