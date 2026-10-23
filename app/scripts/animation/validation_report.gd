class_name ValidationReport
extends RefCounted
## Structured import/validation result. Errors are fatal (avatar rejected); warnings are
## recoverable. A malformed avatar fails gracefully and never destroys the current one.

var errors: Array = []
var warnings: Array = []


func ok() -> bool:
	return errors.is_empty()


func add_error(message: String) -> void:
	errors.append(message)


func add_warning(message: String) -> void:
	warnings.append(message)


func summary() -> String:
	return "errors=%d warnings=%d" % [errors.size(), warnings.size()]


func to_dict() -> Dictionary:
	return {"ok": ok(), "errors": errors, "warnings": warnings}


## Validate a candidate avatar against a rig profile. `actual_bones`/`actual_morphs` are the
## names present on the imported asset; `budget` optionally checks mesh/texture limits.
static func validate(profile: RigProfile, actual_bones: Array, actual_morphs: Array, budget: Dictionary = {}) -> ValidationReport:
	var r := ValidationReport.new()
	var have_bones := {}
	for b in actual_bones:
		have_bones[b] = true
	for b in profile.bones:
		if not have_bones.has(b):
			r.add_error("missing bone: %s" % b)

	var have_morphs := {}
	for m in actual_morphs:
		have_morphs[m] = true
	for m in profile.morphs:
		if not have_morphs.has(m):
			r.add_warning("missing morph channel: %s (speech/expression will be partial)" % m)

	# Unknown extensions / unsupported extras are reported by the importer; here we check
	# budget constraints when provided.
	if budget.has("max_vertices") and int(budget.get("vertex_count", 0)) > int(budget["max_vertices"]):
		r.add_error("vertex budget exceeded: %d > %d" % [int(budget["vertex_count"]), int(budget["max_vertices"])])
	if budget.has("max_texture_size") and int(budget.get("texture_size", 0)) > int(budget["max_texture_size"]):
		r.add_warning("texture size over budget: %d > %d" % [int(budget["texture_size"]), int(budget["max_texture_size"])])
	return r
