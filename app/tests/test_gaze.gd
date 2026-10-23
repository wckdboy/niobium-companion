extends SceneTree
## GazeSolver tests: forward/up/side directions map to expected yaw/pitch; clamping.


static func run(f: TestFramework) -> void:
	# Forward (-Z) -> zero angles.
	var yp := GazeSolver.yaw_pitch(Vector3(0, 0, -1))
	f.check_near(yp.x, 0.0, 0.001, "forward yaw 0")
	f.check_near(yp.y, 0.0, 0.001, "forward pitch 0")

	# Straight left (+X relative to forward) -> yaw ~ +90deg.
	var left := GazeSolver.yaw_pitch(Vector3(1, 0, 0))
	f.check_near(left.x, PI / 2.0, 0.001, "left yaw +90deg")

	# Straight up -> positive pitch.
	var up := GazeSolver.yaw_pitch(Vector3(0, 1, 0))
	f.check_near(up.y, PI / 2.0, 0.001, "up pitch +90deg")

	# Clamping.
	var c := GazeSolver.clamp_angles(1.0, -1.0, 0.4, 0.3)
	f.check_near(c.x, 0.4, 0.001, "yaw clamped")
	f.check_near(c.y, -0.3, 0.001, "pitch clamped")


func _initialize() -> void:
	var f := TestFramework.new()
	run(f)
	quit(f.report("test_gaze"))
