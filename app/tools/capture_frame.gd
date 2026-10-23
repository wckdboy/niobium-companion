extends SceneTree
## Temporary diagnostic: load the main scene, render ~20 frames, capture the viewport to PNG.
## Run WITHOUT --headless: godot --path app --script res://tools/capture_frame.gd

var _frame_count := 0


func _initialize() -> void:
	var scene = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(scene)
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frame_count += 1
	if _frame_count >= 24:
		var img := root.get_texture().get_image()
		var err := img.save_png("user://capture.png")
		print("CAPTURED frames=", _frame_count, " err=", err, " size=", img.get_size())
		quit(0)
