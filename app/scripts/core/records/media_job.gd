class_name MediaJob
extends RefCounted
## A durable async creation job (image, TTS, transcription, video). Progress is persisted and
## resumable; cancellation is explicit; outputs carry provenance.

enum Kind { IMAGE, IMAGE_EDIT, TTS, TRANSCRIPTION, VIDEO, ARTIFACT }
enum State { QUEUED, RUNNING, AWAITING_APPROVAL, SUCCEEDED, FAILED, CANCELLED, INTERRUPTED }

var id: String = ""
var kind: int = Kind.IMAGE
var project_id: String = "default"
var state: int = State.QUEUED
var progress: float = 0.0
var prompt: String = ""
var input_refs: Array = []            # source refs
var output_refs: Array = []           # produced artifacts + provenance
var error: String = ""
var created_at_ms: int = 0
var updated_at_ms: int = 0


static func new_id() -> String:
	return "job_%d_%d" % [Time.get_ticks_msec(), randi() % 0x7fffffff]


func to_dict() -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"project_id": project_id,
		"state": state,
		"progress": progress,
		"prompt": prompt,
		"input_refs": input_refs,
		"output_refs": output_refs,
		"error": error,
		"created_at_ms": created_at_ms,
		"updated_at_ms": updated_at_ms,
	}


static func from_dict(data: Dictionary) -> MediaJob:
	var j := MediaJob.new()
	j.id = str(data.get("id", new_id()))
	j.kind = int(data.get("kind", Kind.IMAGE))
	j.project_id = str(data.get("project_id", "default"))
	j.state = int(data.get("state", State.QUEUED))
	j.progress = float(data.get("progress", 0.0))
	j.prompt = str(data.get("prompt", ""))
	j.input_refs = data.get("input_refs", [])
	j.output_refs = data.get("output_refs", [])
	j.error = str(data.get("error", ""))
	j.created_at_ms = int(data.get("created_at_ms", 0))
	j.updated_at_ms = int(data.get("updated_at_ms", 0))
	return j
