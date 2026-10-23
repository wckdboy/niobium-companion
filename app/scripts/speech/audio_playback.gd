class_name AudioPlayback
extends RefCounted
## Plays sequenced SpeechSegments via AudioStreamPlayer and reports an absolute sample clock.
## The sample clock is the synchronization authority for visemes. Interruption clears the queue
## and stops playback immediately. Device-verified (real audio timing is hardware).

signal finished(generation: int)

var _player: AudioStreamPlayer
var _queue: Array = []              # remaining segments
var _current: SpeechSegment
var _generation := 0
var _sample_rate := 24000
var _base_sample := 0               # sample where the current segment began
var _active := false


func setup(parent: Node) -> void:
	if _player != null:
		return
	_player = AudioStreamPlayer.new()
	_player.set_name("SpeechPlayer")
	parent.add_child(_player)
	_player.finished.connect(_on_player_finished)


func set_sample_rate(sr: int) -> void:
	_sample_rate = sr


func play(segments: Array, generation: int) -> void:
	_generation = generation
	_queue = segments.duplicate()
	_active = false
	_current = null
	_play_next()


func stop() -> void:
	_active = false
	_queue = []
	_current = null
	if _player != null:
		_player.stop()


func is_playing() -> bool:
	return _active


## Absolute sample clock (authority). Falls back to advancing via playback position.
func current_sample() -> int:
	if _current == null or _player == null:
		return _base_sample
	var pos_seconds := _player.get_playback_position()
	return _base_sample + int(pos_seconds * float(_sample_rate))


func _play_next() -> void:
	if _queue.is_empty():
		_active = false
		_current = null
		finished.emit(_generation)
		return
	_current = _queue.pop_front()
	_base_sample = _current.start_sample
	_active = true
	_player.stream = _to_wav(_current)
	_player.play()


func _on_player_finished() -> void:
	if _active:
		_play_next()


func _to_wav(seg: SpeechSegment) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = _sample_rate
	wav.stereo = false
	wav.data = _float_to_pcm16(seg.pcm)
	return wav


static func _float_to_pcm16(samples: PackedFloat32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var v := clampf(samples[i], -1.0, 1.0)
		var s := int(v * 32767.0)
		bytes[i * 2] = s & 0xFF
		bytes[i * 2 + 1] = (s >> 8) & 0xFF
	return bytes
