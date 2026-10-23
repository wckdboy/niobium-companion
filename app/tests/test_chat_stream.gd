extends SceneTree
## Chat stream parser tests: content deltas, reasoning separation, tool-call reassembly,
## finish, usage, errors.


static func run(f: TestFramework) -> void:
	var c := ChatStreamParser.new()

	# Content delta.
	var rec := c.push_data('{"choices":[{"delta":{"content":"Hel"},"index":0}]}')
	f.check_eq(rec.size(), 1, "one content record")
	f.check_eq(rec[0]["type"], "content", "content type")
	f.check_eq(rec[0]["text"], "Hel", "content text")

	# Reasoning separated from spoken text.
	rec = c.push_data('{"choices":[{"delta":{"reasoning_content":"thinking..."},"index":0}]}')
	f.check_eq(rec[0]["type"], "reasoning", "reasoning type")

	# Tool call argument reassembly across chunks.
	c.reset()
	c.push_data('{"choices":[{"delta":{"tool_calls":[{"index":0,"id":"c1","type":"function","function":{"name":"get_weather","arguments":"{\\"ci"}}]}}]}')
	c.push_data('{"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":"ty\\":\\"Paris\\"}"}}]}}]}')
	c.push_data('{"choices":[{"delta":{},"finish_reason":"tool_calls"}]}')
	var tcs := c.get_tool_calls()
	f.check_eq(tcs.size(), 1, "one tool call reassembled")
	f.check_eq(tcs[0]["name"], "get_weather", "tool name")
	f.check_eq(tcs[0]["id"], "c1", "tool id")
	f.check_eq(tcs[0]["arguments"], {"city": "Paris"}, "tool args parsed")

	# Finish + usage.
	c.reset()
	rec = c.push_data('{"choices":[{"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":10,"completion_tokens":4}}')
	var types := []
	for r in rec:
		types.append(r["type"])
	f.check_true(types.has("finish"), "finish emitted")
	f.check_true(types.has("usage"), "usage emitted")

	# Error payload.
	c.reset()
	rec = c.push_data('{"error":{"message":"rate limited","code":"429"}}')
	f.check_eq(rec[0]["type"], "error", "error type")
	f.check_eq(rec[0]["code"], "429", "error code")

	# [DONE].
	c.reset()
	rec = c.push_data("[DONE]")
	f.check_eq(rec[0]["type"], "stream_end", "stream end marker")

	# Malformed JSON does not crash.
	c.reset()
	rec = c.push_data("not json")
	f.check_eq(rec[0]["type"], "parse_error", "parse error surfaced")


func _initialize() -> void:
	var f := TestFramework.new()
	run(f)
	quit(f.report("test_chat_stream"))
