class_name Message
extends RefCounted
## A single chat message. Content stored inline; attachments stored by reference.
## `presented` records only what was actually shown/heard; an interrupted draft is kept
## separately and never presented as spoken.

enum Role { USER, ASSISTANT, SYSTEM, TOOL }
enum Status { DRAFT, STREAMING, PRESENTED, INTERRUPTED, ERROR }

var id: String = ""
var conversation_id: String = ""
var role: int = Role.USER
var content: String = ""
var turn_id: String = ""
var created_at_ms: int = 0
var updated_at_ms: int = 0
var status: int = Status.PRESENTED
var attachments: Array = []            # attachment refs (Dictionary), not blobs
var citations: Array = []              # citation refs
var meta: Dictionary = {}              # e.g. provider, model, usage estimate


static func new_id() -> String:
	return "msg_%d_%d" % [Time.get_ticks_msec(), randi() % 0x7fffffff]


func to_dict() -> Dictionary:
	return {
		"id": id,
		"conversation_id": conversation_id,
		"role": role,
		"content": content,
		"turn_id": turn_id,
		"created_at_ms": created_at_ms,
		"updated_at_ms": updated_at_ms,
		"status": status,
		"attachments": attachments,
		"citations": citations,
		"meta": meta,
	}


static func from_dict(data: Dictionary) -> Message:
	var m := Message.new()
	m.id = str(data.get("id", new_id()))
	m.conversation_id = str(data.get("conversation_id", ""))
	m.role = int(data.get("role", Role.USER))
	m.content = str(data.get("content", ""))
	m.turn_id = str(data.get("turn_id", ""))
	m.created_at_ms = int(data.get("created_at_ms", 0))
	m.updated_at_ms = int(data.get("updated_at_ms", 0))
	m.status = int(data.get("status", Status.PRESENTED))
	m.attachments = data.get("attachments", [])
	m.citations = data.get("citations", [])
	m.meta = data.get("meta", {})
	return m


func is_presented() -> bool:
	return status == Status.PRESENTED
