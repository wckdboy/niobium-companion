class_name ChatStreamParser
extends RefCounted
## Turns OpenAI-compatible chat-completion SSE `data:` payloads into typed records.
## Handles content deltas, reasoning summaries (never leaked to TTS), tool-call argument
## fragments (reassembled across chunks), finish reasons, usage and errors.

# Internal accumulation of tool calls by index -> {id, name, arguments}
var _tool_calls: Dictionary = {}


func reset() -> void:
	_tool_calls = {}


## Feed one raw `data:` value (a JSON string or `[DONE]`); returns an Array of records.
func push_data(data: String) -> Array:
	var out: Array = []
	var trimmed := data.strip_edges()
	if trimmed == "[DONE]":
		out.append({"type": "stream_end"})
		return out

	var j := JSON.new()
	if j.parse(trimmed) != OK:
		out.append({"type": "parse_error", "raw": trimmed.left(120)})
		return out
	var parsed = j.data

	if typeof(parsed) != TYPE_DICTIONARY:
		out.append({"type": "parse_error", "raw": trimmed.left(120)})
		return out

	if parsed.has("error"):
		var e: Dictionary = parsed["error"]
		out.append({
			"type": "error",
			"message": str(e.get("message", "unknown error")),
			"code": e.get("code", ""),
			"raw": trimmed.left(500),
		})
		return out

	var choices: Array = parsed.get("choices", [])
	for choice in choices:
		if typeof(choice) != TYPE_DICTIONARY:
			continue
		_handle_choice(choice, out)

	if parsed.has("usage") and typeof(parsed["usage"]) == TYPE_DICTIONARY:
		var u: Dictionary = parsed["usage"]
		out.append({
			"type": "usage",
			"prompt_tokens": int(u.get("prompt_tokens", 0)),
			"completion_tokens": int(u.get("completion_tokens", 0)),
		})
	return out


## Returns the reassembled tool calls: Array of {index, id, name, arguments (parsed JSON
## or {} when not yet valid)}.
func get_tool_calls() -> Array:
	var result: Array = []
	var keys := _tool_calls.keys()
	keys.sort()
	for k in keys:
		var tc: Dictionary = _tool_calls[k]
		var args = {}
		var arg_str: String = tc.get("arguments", "")
		if not arg_str.is_empty():
			var parsed = JSON.parse_string(arg_str)
			if parsed != null and typeof(parsed) == TYPE_DICTIONARY:
				args = parsed
		result.append({
			"index": int(k),
			"id": tc.get("id", ""),
			"name": tc.get("name", ""),
			"arguments": args,
			"arguments_json": arg_str,
		})
	return result


func _handle_choice(choice: Dictionary, out: Array) -> void:
	var delta: Variant = choice.get("delta", {})
	if typeof(delta) != TYPE_DICTIONARY:
		delta = {}

	# Reasoning summaries (provider-exposed) are separated and never spoken.
	if delta.has("reasoning_content"):
		out.append({"type": "reasoning", "text": str(delta["reasoning_content"])})
	if delta.has("reasoning"):
		out.append({"type": "reasoning", "text": str(delta["reasoning"])})

	if delta.has("content") and delta["content"] != null:
		out.append({"type": "content", "text": str(delta["content"])})

	var tool_calls: Array = delta.get("tool_calls", [])
	for tc in tool_calls:
		if typeof(tc) != TYPE_DICTIONARY:
			continue
		var idx: int = int(tc.get("index", 0))
		if not _tool_calls.has(idx):
			_tool_calls[idx] = {"id": "", "name": "", "arguments": ""}
		var slot: Dictionary = _tool_calls[idx]
		if tc.has("id") and tc["id"] != null and tc["id"] != "":
			slot["id"] = str(tc["id"])
		if tc.has("type"):
			pass
		var func_part: Variant = tc.get("function", {})
		if typeof(func_part) == TYPE_DICTIONARY:
			if func_part.has("name") and func_part["name"] != null:
				slot["name"] = str(func_part["name"])
			if func_part.has("arguments") and func_part["arguments"] != null:
				var frag := str(func_part["arguments"])
				slot["arguments"] = str(slot["arguments"]) + frag
				out.append({
					"type": "tool_call_delta",
					"index": idx,
					"id": slot["id"],
					"name": slot["name"],
					"arguments_delta": frag,
				})

	if choice.has("finish_reason") and choice["finish_reason"] != null:
		out.append({"type": "finish", "reason": str(choice["finish_reason"])})
