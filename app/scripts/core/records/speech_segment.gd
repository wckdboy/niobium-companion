class_name SpeechSegment
extends RefCounted
## A synthesized speech chunk plus its timing and viseme plan. The playback sample clock is
## the synchronization authority; `start_sample`/`duration_samples` are in output PCM frames.

var id: String = ""
var turn_id: String = ""
var generation: int = 0
var seq: int = 0                       # monotonic within a turn
var text: String = ""
var pcm: PackedFloat32Array = PackedFloat32Array()
var sample_rate: int = 24000
var start_sample: int = 0              # absolute output clock (authority)
var duration_samples: int = 0
var visemes: Array = []                # Array of {time_ms, viseme, weight}
var cues: Array = []                   # Array[PerformanceCue] for this segment


static func new_id() -> String:
	return "seg_%d_%d" % [Time.get_ticks_msec(), randi() % 0x7fffffff]


func duration_ms() -> int:
	if sample_rate <= 0:
		return 0
	return int(float(duration_samples) * 1000.0 / float(sample_rate))
