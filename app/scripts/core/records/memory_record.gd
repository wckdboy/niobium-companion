class_name MemoryRecord
extends RefCounted
## A durable memory. Identity, preferences, episodic memories and retrieved documents are
## separate record types. A temporary expression is never a memory.

enum Type { EPISODIC, PREFERENCE, IDENTITY, DOCUMENT, NOTE }
enum Confidence { LOW, MEDIUM, HIGH }

var id: String = ""
var type: int = Type.EPISODIC
var project_id: String = "default"
var content: String = ""
var source_turn_ids: Array = []      # provenance
var source_doc_ids: Array = []
var created_at_ms: int = 0
var updated_at_ms: int = 0
var confidence: int = Confidence.MEDIUM
var deleted: bool = false
var deleted_at_ms: int = 0


static func new_id() -> String:
	return "mem_%d_%d" % [Time.get_ticks_msec(), randi() % 0x7fffffff]


func to_dict() -> Dictionary:
	return {
		"id": id,
		"type": type,
		"project_id": project_id,
		"content": content,
		"source_turn_ids": source_turn_ids,
		"source_doc_ids": source_doc_ids,
		"created_at_ms": created_at_ms,
		"updated_at_ms": updated_at_ms,
		"confidence": confidence,
		"deleted": deleted,
		"deleted_at_ms": deleted_at_ms,
	}


static func from_dict(data: Dictionary) -> MemoryRecord:
	var m := MemoryRecord.new()
	m.id = str(data.get("id", new_id()))
	m.type = int(data.get("type", Type.EPISODIC))
	m.project_id = str(data.get("project_id", "default"))
	m.content = str(data.get("content", ""))
	m.source_turn_ids = data.get("source_turn_ids", [])
	m.source_doc_ids = data.get("source_doc_ids", [])
	m.created_at_ms = int(data.get("created_at_ms", 0))
	m.updated_at_ms = int(data.get("updated_at_ms", 0))
	m.confidence = int(data.get("confidence", Confidence.MEDIUM))
	m.deleted = bool(data.get("deleted", false))
	m.deleted_at_ms = int(data.get("deleted_at_ms", 0))
	return m
