extends SceneTree
## SpeechSession tests: happy-path completion + storage, and interruption dropping stale output.


## Streams "before", then triggers an interrupt callback, then tries to stream "after".
class InterruptingAdapter:
	extends ProviderAdapter
	var on_first: Callable

	func stream_chat(messages: Array, options: Dictionary, on_record: Callable, is_cancelled: Callable) -> Dictionary:
		on_record.call({"type": "content", "text": "before "})
		if on_first.is_valid():
			on_first.call()
		on_record.call({"type": "content", "text": "after "})
		on_record.call({"type": "finish", "reason": "stop"})
		return {"status": "done", "error": "", "model": "", "usage": {}}


static func _make_store(dir: String) -> Store:
	var s := Store.new(dir)
	s.register_migration(0, func(_v): pass)
	s.open()
	return s


static func run(f: TestFramework) -> void:
	# Happy path.
	var dir := TestFramework.test_dir("session_ok")
	var store := _make_store(dir)
	var session := SpeechSession.new()
	session.adapter = ScriptedAdapter.new("hello world friend")
	session.tts = TestTTS.new()
	session.store = store
	var got_segments: Array = []
	session.segments_ready.connect(func(segs): got_segments.append_array(segs))
	session.begin_turn("hi")

	f.check_eq(store.list_records("message").size(), 2, "user + assistant stored")
	var msgs: Array = store.list_records("message")
	msgs.sort_custom(func(a, b): return a["created_at_ms"] < b["created_at_ms"])
	f.check_eq(msgs[0]["role"], Message.Role.USER, "first message is user")
	f.check_eq(msgs[1]["role"], Message.Role.ASSISTANT, "second is assistant")
	f.check_eq(msgs[1]["status"], Message.Status.PRESENTED, "assistant presented")
	f.check_eq(msgs[1]["content"], "hello world friend", "assistant content")
	f.check_true(got_segments.size() > 0, "segments produced for speech")
	TestFramework.cleanup_dir("session_ok")

	# Interruption drops stale output.
	var dir2 := TestFramework.test_dir("session_int")
	var store2 := _make_store(dir2)
	var session2 := SpeechSession.new()
	var ia := InterruptingAdapter.new()
	ia.on_first = func(): session2.interrupt()
	session2.adapter = ia
	session2.tts = TestTTS.new()
	session2.store = store2
	var seg_count := 0
	session2.segments_ready.connect(func(_segs): seg_count += 1)
	session2.begin_turn("hello")

	f.check_eq(seg_count, 0, "no segments after interrupt")
	var msgs2: Array = store2.list_records("message")
	var assistant: Dictionary = {}
	for m in msgs2:
		if m["role"] == Message.Role.ASSISTANT:
			assistant = m
	f.check_eq(assistant.get("status", -1), Message.Status.INTERRUPTED, "assistant marked interrupted")
	f.check_eq(assistant.get("content", ""), "before ", "only pre-interrupt content stored")
	TestFramework.cleanup_dir("session_int")


func _initialize() -> void:
	var f := TestFramework.new()
	run(f)
	quit(f.report("test_session"))
