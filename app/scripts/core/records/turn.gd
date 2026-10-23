class_name Turn
extends RefCounted
## A single user->assistant exchange with a cancellation generation. Every segment and
## network packet carries the turn id + generation so stale output can be dropped.

enum State { NEW, TRANSCRIBING, THINKING, SPEAKING, INTERRUPTED, COMPLETED, ERROR }

var id: String = ""
var conversation_id: String = ""
var generation: int = 0
var state: int = State.NEW
var user_text: String = ""
var assistant_text: String = ""
var created_at_ms: int = 0
var first_token_at_ms: int = 0
var first_audio_at_ms: int = 0
var started_playback_at_ms: int = 0
var interrupted_at_ms: int = 0
var segments: Array = []               # Array[SpeechSegment]
var meta: Dictionary = {}


static func new_id() -> String:
	return "turn_%d_%d" % [Time.get_ticks_msec(), randi() % 0x7fffffff]


## Advance the generation counter; anything tagged with an older generation is stale.
func bump_generation() -> int:
	generation += 1
	return generation


func is_cancelled(gen: int) -> bool:
	return gen != generation
