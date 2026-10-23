class_name SSEParser
extends RefCounted
## Byte-level Server-Sent Events parser. Accepts arbitrary chunks (mid-line, mid-UTF-8,
## CRLF or LF) and emits complete events. Splitting on \n bytes is UTF-8-safe because a
## newline byte never appears inside a multi-byte sequence.

var _buffer := PackedByteArray()
var _data_lines: Array = []
var _event_name := ""
var _event_id := ""


## Feed raw bytes; returns an Array of completed events, each
## { "event": String, "data": String, "id": String }.
func push_bytes(bytes: PackedByteArray) -> Array:
	_buffer.append_array(bytes)
	var events: Array = []
	while true:
		var nl := _buffer.find(0x0A)
		if nl < 0:
			break
		var line_bytes := _buffer.slice(0, nl)
		_buffer = _buffer.slice(nl + 1)
		var line := line_bytes.get_string_from_utf8()
		if line.ends_with("\r"):
			line = line.substr(0, line.length() - 1)
		if line.is_empty():
			if not _data_lines.is_empty() or not _event_name.is_empty():
				events.append(_build_event())
				_reset_event()
			continue
		_handle_line(line)
	return events


## Flush any pending event at end-of-stream (no trailing blank line required).
func flush() -> Array:
	if not _buffer.is_empty():
		var line := _buffer.get_string_from_utf8()
		_buffer = PackedByteArray()
		if line.ends_with("\r"):
			line = line.substr(0, line.length() - 1)
		if not line.is_empty():
			_handle_line(line)
	var events: Array = []
	if not _data_lines.is_empty() or not _event_name.is_empty():
		events.append(_build_event())
		_reset_event()
	return events


func reset() -> void:
	_buffer = PackedByteArray()
	_reset_event()


func _handle_line(line: String) -> void:
	if line.begins_with(":"):
		return  # comment
	var colon := line.find(":")
	var field := line
	var value := ""
	if colon >= 0:
		field = line.substr(0, colon)
		value = line.substr(colon + 1)
		if value.begins_with(" "):
			value = value.substr(1)
	match field:
		"data":
			_data_lines.append(value)
		"event":
			_event_name = value
		"id":
			# "id" with a null value means reset, per spec.
			if value != "" and value != "\u0000":
				_event_id = value
		"retry":
			pass


func _build_event() -> Dictionary:
	return {
		"event": _event_name,
		"data": "\n".join(_data_lines),
		"id": _event_id,
	}


func _reset_event() -> void:
	_data_lines = []
	_event_name = ""
	_event_id = ""
