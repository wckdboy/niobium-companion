class_name ProviderTTS
extends TTSProvider
## OpenAI-compatible `/audio/speech` adapter. Scaffolded; live synthesis is NOT implemented in
## this build (requires credentials + real HTTP against the owner's provider). Returns no
## segments and records `last_error` so the session can surface "TTS unavailable" honestly.

var profile: ProviderProfile
var voice: String = "alloy"
var format: String = "wav"
var last_error: String = ""


func _init(p: ProviderProfile = null) -> void:
	profile = p if p != null else ProviderProfile.new()


func synthesize(text: String, is_cancelled: Callable = Callable()) -> Array:
	last_error = "ProviderTTS: live audio/speech synthesis not implemented (needs credentials + HTTP)."
	return []
