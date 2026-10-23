class_name TTSProvider
extends RefCounted
## Text-to-speech interface. Implementations return SpeechSegments carrying PCM + a viseme
## plan. Streaming (chunked) synthesis is achieved by returning multiple segments; the
## SpeechSession sequences them by `seq` regardless of arrival order.

func sample_rate() -> int:
	return 24000


## Return Array[SpeechSegment] for `text`. `is_cancelled` may abort early when valid.
func synthesize(text: String, is_cancelled: Callable = Callable()) -> Array:
	return []
