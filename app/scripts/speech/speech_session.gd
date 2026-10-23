class_name SpeechSession
extends RefCounted
## Orchestrates a turn: LLM stream -> assistant text -> TTS -> sequenced segments -> playback,
## with interruption that cancels network work, drops stale output and stores only what was
## presented. Collaborators are injected so it is testable without network or audio.

signal state_changed(turn: Turn)
signal text_delta(turn_id: String, delta: String)
signal segments_ready(segments: Array)
signal turn_finished(turn: Turn)

var adapter: ProviderAdapter
var tts: TTSProvider
var store: Store
var credentials: CredentialStore
var system_prompt: String = ""
var conversation_id: String = "default"
var project_id: String = "default"

var _turn: Turn
var _sequencer := SegmentSequencer.new()
var _assistant_text := ""
var _messages: Array = []            # Array[Message] in-memory mirror of the conversation


func current_turn() -> Turn:
	return _turn


func begin_turn(user_text: String) -> void:
	if _turn != null:
		interrupt()
	var turn := Turn.new()
	turn.id = Turn.new_id()
	turn.conversation_id = conversation_id
	turn.generation = 1
	turn.state = Turn.State.THINKING
	turn.user_text = user_text
	turn.created_at_ms = Time.get_ticks_msec()
	_turn = turn
	_assistant_text = ""
	_sequencer.reset()
	_sequencer.set_sample_rate(tts.sample_rate() if tts != null else 24000)
	_append_message(Message.Role.USER, user_text, Message.Status.PRESENTED, turn)
	state_changed.emit(turn)
	_run_turn(turn)


func interrupt() -> void:
	if _turn == null:
		return
	var turn: Turn = _turn
	_turn = null
	turn.bump_generation()
	turn.state = Turn.State.INTERRUPTED
	turn.interrupted_at_ms = Time.get_ticks_msec()
	_store_assistant(turn, Message.Status.INTERRUPTED)
	state_changed.emit(turn)
	turn_finished.emit(turn)


func _run_turn(turn: Turn) -> void:
	if adapter == null:
		turn.state = Turn.State.ERROR
		turn.meta["error"] = "no provider adapter configured"
		_store_assistant(turn, Message.Status.ERROR)
		turn_finished.emit(turn)
		return

	var summary: Dictionary = await adapter.stream_chat(
		_build_messages(turn), _llm_options(),
		func(record: Dictionary) -> void: _on_record(turn, record),
		func() -> bool: return _is_cancelled(turn))

	if _turn != turn:
		return  # interrupted while streaming

	if summary.get("status", "") == "error":
		turn.state = Turn.State.ERROR
		turn.meta["error"] = summary.get("error", "")
		_store_assistant(turn, Message.Status.ERROR)
		turn_finished.emit(turn)
		return

	if _assistant_text.is_empty():
		turn.state = Turn.State.COMPLETED
		_store_assistant(turn, Message.Status.PRESENTED)
		turn_finished.emit(turn)
		return

	# Speech phase.
	turn.state = Turn.State.SPEAKING
	state_changed.emit(turn)
	var segments: Array = []
	if tts != null:
		segments = tts.synthesize(_assistant_text, func() -> bool: return _is_cancelled(turn))
	if _turn != turn:
		return  # interrupted during synthesis

	var ready := _enqueue(turn, segments)
	if not ready.is_empty():
		segments_ready.emit(ready)
	if _assistant_text != "":
		_store_assistant(turn, Message.Status.PRESENTED)


func _enqueue(turn: Turn, segments: Array) -> Array:
	var ready: Array = []
	for seg in segments:
		if typeof(seg) != TYPE_OBJECT or not (seg is SpeechSegment):
			continue
		seg.turn_id = turn.id
		seg.generation = turn.generation
		var batch: Array = _sequencer.submit(seg)
		for b in batch:
			ready.append(b)
	return ready


func _on_record(turn: Turn, record: Dictionary) -> void:
	if _turn != turn:
		return
	match str(record.get("type", "")):
		"content":
			_assistant_text += str(record.get("text", ""))
			text_delta.emit(turn.id, str(record.get("text", "")))
		"reasoning":
			turn.meta["reasoning"] = str(turn.meta.get("reasoning", "")) + str(record.get("text", ""))
		"error":
			turn.state = Turn.State.ERROR
			turn.meta["error"] = record.get("message", "")
		"finish":
			turn.meta["finish_reason"] = record.get("reason", "")


func _is_cancelled(turn: Turn) -> bool:
	return _turn != turn


func _llm_options() -> Dictionary:
	return {
		"model": _model_for_turn(),
	}


func _model_for_turn() -> String:
	if adapter is OpenAICompatibleAdapter and not (adapter as OpenAICompatibleAdapter).profile.default_model.is_empty():
		return (adapter as OpenAICompatibleAdapter).profile.default_model
	return ""


func _build_messages(turn: Turn) -> Array:
	var msgs: Array = []
	if not system_prompt.is_empty():
		msgs.append({"role": "system", "content": system_prompt})
	for m in _messages:
		msgs.append({"role": _role_name(m.role), "content": m.content})
	msgs.append({"role": "user", "content": turn.user_text})
	return msgs


func _append_message(role: int, content: String, status: int, turn: Turn) -> Message:
	var m := Message.new()
	m.id = Message.new_id()
	m.conversation_id = conversation_id
	m.role = role
	m.content = content
	m.turn_id = turn.id
	m.status = status
	m.created_at_ms = Time.get_ticks_msec()
	m.updated_at_ms = m.created_at_ms
	_messages.append(m)
	if store != null:
		store.put_record("message", m.id, m.to_dict())
		_touch_conversation()
	return m


func _store_assistant(turn: Turn, status: int) -> void:
	_append_message(Message.Role.ASSISTANT, _assistant_text, status, turn)


func _touch_conversation() -> void:
	if store == null:
		return
	var conv: Dictionary = store.get_record("conversation", conversation_id)
	if conv.is_empty():
		conv = {"id": conversation_id, "project_id": project_id, "title": "", "message_ids": [], "created_at_ms": Time.get_ticks_msec()}
	var ids: Array = conv.get("message_ids", [])
	ids.clear()
	for m in _messages:
		ids.append(m.id)
	conv["message_ids"] = ids
	conv["updated_at_ms"] = Time.get_ticks_msec()
	if conv.get("title", "") == "" and not _messages.is_empty():
		conv["title"] = _messages[0].content.left(48)
	store.put_record("conversation", conversation_id, conv)


static func _role_name(role: int) -> String:
	match role:
		Message.Role.ASSISTANT:
			return "assistant"
		Message.Role.SYSTEM:
			return "system"
		Message.Role.TOOL:
			return "tool"
		_:
			return "user"


## Restore conversation messages from the store into the in-memory mirror.
func load_conversation() -> void:
	_messages = []
	if store == null:
		return
	var conv: Dictionary = store.get_record("conversation", conversation_id)
	for id in conv.get("message_ids", []):
		var d: Dictionary = store.get_record("message", str(id))
		if not d.is_empty():
			_messages.append(Message.from_dict(d))
	_messages.sort_custom(func(a, b): return a.created_at_ms < b.created_at_ms)
