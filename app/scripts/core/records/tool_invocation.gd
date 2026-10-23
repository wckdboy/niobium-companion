class_name ToolInvocation
extends RefCounted
## A tool run. State is transactional and recoverable; non-idempotent side effects require
## approval and must not auto-repeat after a crash.

enum State { QUEUED, RUNNING, AWAITING_APPROVAL, SUCCEEDED, FAILED, CANCELLED, INTERRUPTED }

var id: String = ""
var turn_id: String = ""
var tool: String = ""
var args: Dictionary = {}
var state: int = State.QUEUED
var idempotency_key: String = ""
var result: Dictionary = {}
var error: String = ""
var created_at_ms: int = 0
var updated_at_ms: int = 0


static func new_id() -> String:
	return "tool_%d_%d" % [Time.get_ticks_msec(), randi() % 0x7fffffff]


func is_terminal() -> bool:
	return state == State.SUCCEEDED or state == State.FAILED or state == State.CANCELLED


func is_side_effecting() -> bool:
	# Deletion, messaging, expensive media, broad machine access.
	return not idempotency_key.is_empty()
