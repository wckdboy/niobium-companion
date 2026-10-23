extends SceneTree
## Test runner. Loads each deterministic test module and aggregates results. Exit code 0 means
## all passed. Run with:
##   godot --headless --path app --script res://tests/run_all.gd


const MODULES := [
	"res://tests/test_sse.gd",
	"res://tests/test_chat_stream.gd",
	"res://tests/test_store.gd",
	"res://tests/test_sequencer.gd",
	"res://tests/test_session.gd",
	"res://tests/test_viseme.gd",
	"res://tests/test_cue.gd",
	"res://tests/test_animation.gd",
	"res://tests/test_validation.gd",
	"res://tests/test_gaze.gd",
	"res://tests/test_rig.gd",
	"res://tests/test_gltf.gd",
]


func _initialize() -> void:
	var total_fail := 0
	var total_pass := 0
	for path in MODULES:
		var s = load(path)
		if s == null:
			print("[run_all] could not load %s" % path)
			total_fail += 1
			continue
		var f := TestFramework.new()
		s.run(f)
		total_pass += f.pass_count
		total_fail += f.fail_count
		f.report(path.get_file())
	print("======================================")
	print("[run_all] total pass=%d fail=%d" % [total_pass, total_fail])
	print("[run_all] %s" % ("ALL TESTS PASSED" if total_fail == 0 else "FAILURES PRESENT"))
	quit(1 if total_fail > 0 else 0)
