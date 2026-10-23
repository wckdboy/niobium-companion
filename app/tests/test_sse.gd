extends SceneTree
## SSE byte-level parser tests: event framing, CRLF, fragmented UTF-8, comments, [DONE].


static func run(f: TestFramework) -> void:
	var p := SSEParser.new()

	# Simple single event.
	var ev := p.push_bytes("data: hello\n\n".to_utf8_buffer())
	f.check_eq(ev.size(), 1, "single event parsed")
	f.check_eq(ev[0]["data"], "hello", "data value")
	f.check_eq(ev[0]["event"], "", "default event name empty")

	# CRLF framing.
	p.reset()
	ev = p.push_bytes("data: a\r\ndata: b\r\n\r\n".to_utf8_buffer())
	f.check_eq(ev.size(), 1, "CRLF multi-line single event")
	f.check_eq(ev[0]["data"], "a\nb", "multi-line data joined by newline")

	# Two events separated by blank line.
	p.reset()
	ev = p.push_bytes("data: one\n\ndata: two\n\n".to_utf8_buffer())
	f.check_eq(ev.size(), 2, "two events")
	f.check_eq(ev[0]["data"], "one", "first event data")
	f.check_eq(ev[1]["data"], "two", "second event data")

	# Comment lines ignored.
	p.reset()
	ev = p.push_bytes(": keep-alive\ndata: x\n\n".to_utf8_buffer())
	f.check_eq(ev.size(), 1, "comment ignored")
	f.check_eq(ev[0]["data"], "x", "data after comment")

	# Event name and id.
	p.reset()
	ev = p.push_bytes("event: ping\nid: 42\ndata: {}\n\n".to_utf8_buffer())
	f.check_eq(ev[0]["event"], "ping", "event name")
	f.check_eq(ev[0]["id"], "42", "event id")

	# Fragmented across pushes (mid-line).
	p.reset()
	var a := p.push_bytes("data: hel".to_utf8_buffer())
	f.check_eq(a.size(), 0, "no event before newline")
	var b := p.push_bytes("lo\n\n".to_utf8_buffer())
	f.check_eq(b.size(), 1, "event after completion")
	f.check_eq(b[0]["data"], "hello", "reassembled data")

	# Fragmented UTF-8: split a multibyte char across chunk boundaries.
	p.reset()
	var emoji := "😀"  # 4 bytes
	var emoji_bytes := emoji.to_utf8_buffer()
	var half := emoji_bytes.slice(0, 2)
	var rest := emoji_bytes.slice(2)
	p.push_bytes("data: a".to_utf8_buffer() + half)
	var ev2 := p.push_bytes(rest + "\n\n".to_utf8_buffer())
	f.check_eq(ev2.size(), 1, "utf8 event parsed")
	f.check_eq(ev2[0]["data"], "a😀", "utf8 reassembled correctly")

	# Flush with no trailing blank line.
	p.reset()
	p.push_bytes("data: tail".to_utf8_buffer())
	var tail := p.flush()
	f.check_eq(tail.size(), 1, "flush emits pending")
	f.check_eq(tail[0]["data"], "tail", "flush data")


func _initialize() -> void:
	var f := TestFramework.new()
	run(f)
	quit(f.report("test_sse"))
