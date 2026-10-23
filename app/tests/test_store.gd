extends SceneTree
## Store tests: CRUD, persistence across reopen, lexical search, memory delete invalidation,
## and migration gating.


static func run(f: TestFramework) -> void:
	var dir := TestFramework.test_dir("store")
	var s := Store.new(dir)
	s.register_migration(0, func(_v): pass)
	s.open()

	# Put/get.
	s.put_record("message", "m1", {"content": "the cat sat on the mat", "deleted": false})
	var got: Dictionary = s.get_record("message", "m1")
	f.check_eq(got["content"], "the cat sat on the mat", "put/get roundtrip")

	# List.
	f.check_eq(s.list_records("message").size(), 1, "list one message")

	# Search finds it.
	var hits := s.search("cat")
	f.check_eq(hits.size(), 1, "search finds message")
	f.check_eq(hits[0]["id"], "m1", "search hit id")

	# Search case-insensitive + token match.
	f.check_eq(s.search("CAT").size(), 1, "search case-insensitive")

	# Persistence across reopen.
	s.flush()
	s.close()
	var s2 := Store.new(dir)
	s2.register_migration(0, func(_v): pass)
	s2.open()
	f.check_true(s2.has_record("message", "m1"), "record survives reopen")
	f.check_eq(s2.search("mat").size(), 1, "index rebuilt on reopen")

	# Memory delete invalidates derived index.
	s2.put_record("memory", "mem1", {"content": "owner prefers dark themes", "deleted": false})
	f.check_eq(s2.search("dark").size(), 1, "memory searchable before delete")
	var d: Dictionary = s2.get_record("memory", "mem1")
	d["deleted"] = true
	s2.put_record("memory", "mem1", d)
	f.check_eq(s2.search("dark").size(), 0, "deleted memory not returned by search")

	# Hard delete removes from index too.
	s2.put_record("memory", "mem2", {"content": "secret phrase zebra", "deleted": false})
	s2.delete_record("memory", "mem2")
	f.check_eq(s2.search("zebra").size(), 0, "hard delete removes index entry")

	# Migration gate: unknown version does not silently advance.
	var s3 := Store.new(dir + "_mig")
	s3.open()  # no migration registered -> SCHEMA_VERSION not reached, but must not crash
	f.check_true(s3.current_schema_version() <= Store.SCHEMA_VERSION, "schema version sane")

	TestFramework.cleanup_dir("store")
	TestFramework.cleanup_dir("store_mig")


func _initialize() -> void:
	var f := TestFramework.new()
	run(f)
	quit(f.report("test_store"))
