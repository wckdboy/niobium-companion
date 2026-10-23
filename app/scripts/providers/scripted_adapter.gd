class_name ScriptedAdapter
extends ProviderAdapter
## Offline development/demo adapter (clearly labelled, NOT a live provider). Streams a canned
## response synchronously so the full pipeline can be exercised without credentials or network.
## Never presented as evidence of live integration.

var response: String = "Hello — I am Niobium, your companion."
var model: String = "scripted-demo"


func _init(text: String = "") -> void:
	if text != "":
		response = text


func build_chat_request(messages: Array, options: Dictionary) -> Dictionary:
	return {"url": "", "headers": [], "body": ""}


func stream_chat(messages: Array, options: Dictionary, on_record: Callable, is_cancelled: Callable) -> Dictionary:
	# Emit content in small chunks to exercise incremental rendering.
	var words := Store.tokenize(response)
	var count := words.size()
	for i in count:
		if is_cancelled.is_valid() and is_cancelled.call():
			return {"status": "cancelled", "error": "", "model": model, "usage": {}}
		var text: String = str(words[i])
		if i < count - 1:
			text += " "
		on_record.call({"type": "content", "text": text})
	on_record.call({"type": "finish", "reason": "stop"})
	return {"status": "done", "error": "", "model": model, "usage": {}}
