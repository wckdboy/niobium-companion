class_name ApprovalDecision
extends RefCounted
## Owner decision on a tool/task that requires visible approval. Tools never inherit
## permission from mood or a model suggestion.

var tool_invocation_id: String = ""
var approved: bool = false
var scope: String = ""          # human-readable scope of what is being authorized
var requested_at_ms: int = 0
var decided_at_ms: int = 0
var reason: String = ""


func to_dict() -> Dictionary:
	return {
		"tool_invocation_id": tool_invocation_id,
		"approved": approved,
		"scope": scope,
		"requested_at_ms": requested_at_ms,
		"decided_at_ms": decided_at_ms,
		"reason": reason,
	}


static func from_dict(data: Dictionary) -> ApprovalDecision:
	var a := ApprovalDecision.new()
	a.tool_invocation_id = str(data.get("tool_invocation_id", ""))
	a.approved = bool(data.get("approved", false))
	a.scope = str(data.get("scope", ""))
	a.requested_at_ms = int(data.get("requested_at_ms", 0))
	a.decided_at_ms = int(data.get("decided_at_ms", 0))
	a.reason = str(data.get("reason", ""))
	return a
