class_name OpenAICompatibleAdapter
extends ProviderAdapter
## OpenAI-compatible chat completions with streaming SSE and tools (ADR-003). One transport
## serves many named profiles (DeepSeek, OpenCode Go, Abliteration, OpenRouter, Ollama,
## llama.cpp, LM Studio, vLLM, ...).

var profile: ProviderProfile

var _sse := SSEParser.new()
var _chat := ChatStreamParser.new()


func _init(p: ProviderProfile = null) -> void:
	profile = p if p != null else ProviderProfile.new()


func _url_for(path: String) -> String:
	var base: String = profile.base_url.trim_suffix("/")
	return base + path


func _auth_headers() -> Array:
	# Credentials come from the CredentialStore at call time; this adapter only adds the
	# header *name/prefix* from the profile. The secret is never part of the profile.
	return []


## Build the request. `credential` is the resolved secret (injected by the session, never
## persisted here). Pure and unit-testable.
func build_chat_request(messages: Array, options: Dictionary, credential: String = "") -> Dictionary:
	var url := _url_for(options.get("path", "/chat/completions"))
	var headers: Array = [
		"Accept: text/event-stream",
		"Content-Type: application/json",
	]
	# Custom headers from the profile (e.g. OpenRouter HTTP-Referer).
	for k in profile.extra_headers:
		headers.append("%s: %s" % [k, profile.extra_headers[k]])

	if profile.auth_mode == ProviderProfile.AuthMode.API_KEY and credential != "":
		headers.append("%s: %s%s" % [profile.auth_header, profile.auth_prefix, credential])
	elif profile.auth_mode == ProviderProfile.AuthMode.CUSTOM_HEADER and credential != "":
		headers.append("%s: %s" % [profile.auth_header, credential])

	var body := _build_body(messages, options)
	return {"url": url, "headers": headers, "body": JSON.stringify(body)}


func _build_body(messages: Array, options: Dictionary) -> Dictionary:
	var body: Dictionary = {
		"model": str(options.get("model", profile.default_model)),
		"messages": messages,
		"stream": true,
	}
	if options.has("temperature"):
		body["temperature"] = float(options["temperature"])
	if options.has("top_p"):
		body["top_p"] = float(options["top_p"])
	if options.has("max_tokens"):
		body["max_tokens"] = int(options["max_tokens"])
	if options.has("seed"):
		body["seed"] = int(options["seed"])
	if options.has("tools") and not (options["tools"] as Array).is_empty():
		body["tools"] = options["tools"]
		body["tool_choice"] = options.get("tool_choice", "auto")
	if options.has("response_format"):
		body["response_format"] = options["response_format"]
	if options.has("extra_body") and typeof(options["extra_body"]) == TYPE_DICTIONARY:
		for k in options["extra_body"]:
			body[k] = options["extra_body"][k]
	return body


## Feed raw response bytes through the SSE + chat parsers, invoking on_record per record.
## Returns nothing; used both by the live transport and by deterministic tests.
func consume_bytes(bytes: PackedByteArray, on_record: Callable) -> void:
	for ev in _sse.push_bytes(bytes):
		_emit_event(ev, on_record)


func consume_finish(on_record: Callable) -> void:
	for ev in _sse.flush():
		_emit_event(ev, on_record)


func reset_stream() -> void:
	_sse.reset()
	_chat.reset()


func _emit_event(ev: Dictionary, on_record: Callable) -> void:
	if on_record.is_valid():
		on_record.call(ev)


## Live streaming using the low-level HTTP client. Non-blocking; yields between polls.
func stream_chat(messages: Array, options: Dictionary, on_record: Callable, is_cancelled: Callable, credential: String = "") -> Dictionary:
	reset_stream()
	var req := build_chat_request(messages, options, credential)
	var client := HttpStreamClient.new()
	client.open(req["url"], req["headers"], req["body"])
	var status := "running"
	var error := ""
	var usage: Dictionary = {}

	while true:
		var polled := client.poll(on_record, is_cancelled)
		if polled == HttpStreamClient.State.ERROR:
			error = client.error_message()
			status = "error"
			break
		if polled == HttpStreamClient.State.DONE:
			status = "done"
			break
		if is_cancelled.call():
			status = "cancelled"
			break
		await Engine.get_main_loop().process_frame

	# Drain any final records that arrived with the last poll.
	consume_finish(on_record)
	client.close()
	return {"status": status, "error": error, "model": str(options.get("model", "")), "usage": usage}
