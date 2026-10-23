class_name TestFramework
extends RefCounted
## Minimal deterministic test harness. No display, no credentials. Each check() records a pass
## or a named failure; report() prints a summary and returns a process exit code (0 = pass).

var pass_count := 0
var fail_count := 0
var failures: Array = []


func check(cond: bool, msg: String) -> void:
	if cond:
		pass_count += 1
	else:
		fail_count += 1
		failures.append(msg)
		push_error("FAIL: " + msg)


func check_eq(a, b, msg: String) -> void:
	check(a == b, "%s (got %s, want %s)" % [msg, str(a), str(b)])


func check_ne(a, b, msg: String) -> void:
	check(a != b, "%s (unexpected equal: %s)" % [msg, str(a)])


func check_near(a: float, b: float, eps: float, msg: String) -> void:
	check(absf(a - b) <= eps, "%s (got %f, want %f ± %f)" % [msg, a, b, eps])


func check_true(cond: bool, msg: String) -> void:
	check(cond, msg)


func check_false(cond: bool, msg: String) -> void:
	check(not cond, msg)


func report(name: String) -> int:
	print("[%s] pass=%d fail=%d" % [name, pass_count, fail_count])
	for f in failures:
		print("    FAIL: " + f)
	return 1 if fail_count > 0 else 0


## A unique test data directory under user://, cleaned up with cleanup_dir().
static func test_dir(name: String) -> String:
	var d := "user://niobium_tests/" + name
	DirAccess.make_dir_recursive_absolute(d)
	return d


static func cleanup_dir(name: String) -> void:
	var d := "user://niobium_tests/" + name
	if DirAccess.dir_exists_absolute(d):
		var dir := DirAccess.open(d)
		if dir != null:
			dir.list_dir_begin()
			var f := dir.get_next()
			while f != "":
				dir.remove(f)
				f = dir.get_next()
			dir.list_dir_end()
		DirAccess.remove_absolute(d)
