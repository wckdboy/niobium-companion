class_name Conversation
extends RefCounted
## Project-scoped conversation container. Messages are stored separately by
## `conversation_id`; this record holds metadata and ordering.

var id: String = ""
var project_id: String = "default"
var title: String = ""
var created_at_ms: int = 0
var updated_at_ms: int = 0
var message_ids: Array = []          # ordered message ids
var meta: Dictionary = {}


static func new_id() -> String:
	return "conv_%d_%d" % [Time.get_ticks_msec(), randi() % 0x7fffffff]


func to_dict() -> Dictionary:
	return {
		"id": id,
		"project_id": project_id,
		"title": title,
		"created_at_ms": created_at_ms,
		"updated_at_ms": updated_at_ms,
		"message_ids": message_ids,
		"meta": meta,
	}


static func from_dict(data: Dictionary) -> Conversation:
	var c := Conversation.new()
	c.id = str(data.get("id", new_id()))
	c.project_id = str(data.get("project_id", "default"))
	c.title = str(data.get("title", ""))
	c.created_at_ms = int(data.get("created_at_ms", 0))
	c.updated_at_ms = int(data.get("updated_at_ms", 0))
	c.message_ids = data.get("message_ids", [])
	c.meta = data.get("meta", {})
	return c
