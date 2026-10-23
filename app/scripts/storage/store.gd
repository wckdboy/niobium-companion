class_name Store
extends RefCounted
## Durable local store. Concrete JSON backend today (ADR-002); a SQLite backend behind the
## Rust core will implement this same method set. Documents are stored per `type`, keyed by
## `id`, with a write-ahead-style atomic temp+rename on every flush and a lexical search
## index over indexed text fields.

const BACKEND := "json"
const SCHEMA_VERSION := 1
const META_FILE := "meta.json"

## Text-bearing types indexed for lexical search.
const INDEXED_TYPES := ["message", "memory", "note"]

var base_path: String = ""

var _docs: Dictionary = {}                 # type -> { id -> doc }
var _index: Dictionary = {}                # token -> { "type/id" -> true }
var _migrations: Dictionary = {}           # from_version -> Callable(from_version)->void
var _open := false


func _init(path: String = "") -> void:
	base_path = path if path != "" else "user://data"


## --- lifecycle ---------------------------------------------------------------

func open() -> void:
	DirAccess.make_dir_recursive_absolute(base_path)
	_migrate()
	_load_all()
	_rebuild_index()
	_open = true


func close() -> void:
	flush()
	_open = false


## --- migrations --------------------------------------------------------------

func register_migration(from_version: int, fn: Callable) -> void:
	_migrations[from_version] = fn


func current_schema_version() -> int:
	var meta := _read_meta()
	return int(meta.get("schema_version", 0))


func _migrate() -> void:
	var version := current_schema_version()
	while version < SCHEMA_VERSION:
		if not _migrations.has(version):
			push_error("Store: no migration registered from schema %d (to %d)" % [version, SCHEMA_VERSION])
			return
		var fn: Callable = _migrations[version]
		fn.call(version)
		version += 1
		_write_meta({"schema_version": version})


## --- CRUD --------------------------------------------------------------------

func put_record(type: String, id: String, doc: Dictionary) -> void:
	if not _docs.has(type):
		_docs[type] = {}
	_docs[type][id] = doc.duplicate(true)
	_index_record(type, id, doc)


func get_record(type: String, id: String) -> Dictionary:
	if not _docs.has(type):
		return {}
	var d: Dictionary = _docs[type].get(id, {})
	return d.duplicate(true)


func delete_record(type: String, id: String) -> void:
	if not _docs.has(type):
		return
	if _docs[type].has(id):
		_unindex_record(type, id)
		_docs[type].erase(id)


func list_records(type: String) -> Array:
	if not _docs.has(type):
		return []
	var out: Array = []
	for id in _docs[type]:
		out.append(_docs[type][id].duplicate(true))
	return out


func has_record(type: String, id: String) -> bool:
	return _docs.has(type) and _docs[type].has(id)


## --- search (lexical) --------------------------------------------------------

## Returns matching docs across `types` (defaults to all indexed types). Deleted records
## and soft-deleted memory are excluded.
func search(text: String, types: Array = []) -> Array:
	if types.is_empty():
		types = INDEXED_TYPES
	var tokens := tokenize(text)
	if tokens.is_empty():
		return []
	var hits: Dictionary = {}
	var first := true
	for token in tokens:
		var postings: Dictionary = _index.get(token, {})
		var allowed: Dictionary = {}
		for key in postings:
			var type: String = str(key).split("/")[0]
			if types.has(type):
				allowed[key] = true
		if first:
			hits = allowed
			first = false
		else:
			var intersection := {}
			for key in hits:
				if allowed.has(key):
					intersection[key] = true
			hits = intersection
		if hits.is_empty():
			return []
	var out: Array = []
	for key in hits:
		var parts: Array = str(key).split("/")
		var type: String = parts[0]
		var id: String = parts[1]
		var doc := get_record(type, id)
		if doc.is_empty():
			continue
		if doc.get("deleted", false):
			continue
		out.append({"type": type, "id": id, "doc": doc})
	return out


## --- indexing ----------------------------------------------------------------

func _index_record(type: String, id: String, doc: Dictionary) -> void:
	if not INDEXED_TYPES.has(type):
		return
	var text := _indexable_text(type, doc)
	for token in tokenize(text):
		var key := "%s/%s" % [type, id]
		if not _index.has(token):
			_index[token] = {}
		_index[token][key] = true


func _unindex_record(type: String, id: String) -> void:
	if not INDEXED_TYPES.has(type):
		return
	var key := "%s/%s" % [type, id]
	for token in _index:
		var postings: Dictionary = _index[token]
		postings.erase(key)


func _rebuild_index() -> void:
	_index = {}
	for type in _docs:
		for id in _docs[type]:
			_index_record(type, id, _docs[type][id])


static func _indexable_text(type: String, doc: Dictionary) -> String:
	match type:
		"message":
			return str(doc.get("content", ""))
		"memory":
			return str(doc.get("content", ""))
		"note":
			return str(doc.get("content", ""))
	return ""


## --- tokenization ------------------------------------------------------------

static func tokenize(text: String) -> Array:
	var tokens: Array = []
	var current := ""
	for i in text.length():
		var c := text[i]
		var cp := c.unicode_at(0)
		var is_word := (cp >= 48 and cp <= 57) or (cp >= 65 and cp <= 90) \
			or (cp >= 97 and cp <= 122) or cp > 127
		if is_word:
			current += c.to_lower()
		else:
			if current != "":
				tokens.append(current)
				current = ""
	if current != "":
		tokens.append(current)
	return tokens


## --- persistence -------------------------------------------------------------

func flush() -> void:
	if not _docs.is_empty():
		for type in _docs:
			_write_json("%s/%s.json" % [base_path, _sanitize_type(type)], _docs[type])
	_write_meta({"schema_version": SCHEMA_VERSION})


func _load_all() -> void:
	_docs = {}
	var dir := DirAccess.open(base_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".json") and f != META_FILE:
			var type := f.trim_suffix(".json")
			var data = _read_json("%s/%s" % [base_path, f])
			if typeof(data) == TYPE_DICTIONARY:
				_docs[type] = data
		f = dir.get_next()
	dir.list_dir_end()


func _read_meta() -> Dictionary:
	var data = _read_json("%s/%s" % [base_path, META_FILE])
	return data if typeof(data) == TYPE_DICTIONARY else {}


func _write_meta(meta: Dictionary) -> void:
	_write_json("%s/%s" % [base_path, META_FILE], meta)


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	return parsed if parsed != null else {}


func _write_json(path: String, data: Dictionary) -> void:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Store: cannot write %s" % path)
		return
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	DirAccess.rename_absolute(tmp, path)


static func _sanitize_type(type: String) -> String:
	return type.replace("/", "_").replace("\\", "_")
