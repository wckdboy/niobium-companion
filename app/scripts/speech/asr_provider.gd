class_name ASRProvider
extends RefCounted
## Speech-to-text interface (mic -> VAD -> transcription). The microphone pipeline is a
## device feature and is NOT verified in this build environment (no mic/hardware). This
## interface and a push-to-talk stub are provided so the session can be wired without
## pretending offline transcription works.

## Transcribe an in-memory PCM buffer; returns "" when unavailable. Device implementations
## will stream from the mic with VAD + echo cancellation.
func transcribe(pcm: PackedFloat32Array, sample_rate: int, is_cancelled: Callable = Callable()) -> String:
	return ""


func available() -> bool:
	return false
