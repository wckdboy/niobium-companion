class_name CompanionStage
extends Node3D
## Scene orchestration: owns the rig, layered animation director, viseme timeline, audio
## playback and the camera rig. Wires the SpeechSession's segments to playback + lip-sync and
## stops everything cleanly on interruption. This is the single place the render loop touches
## the speech/network pipeline (and it never awaits network itself).

signal camera_mode_changed(mode: String)

var rig: EngineeringRig
var director := AnimationDirector.new()
var viseme_profile := VisemeProfile.default_profile()
var timeline := VisemeTimeline.new()
var playback := AudioPlayback.new()

var camera: Camera3D
var _camera_target_pos := Vector3.ZERO
var _camera_look := Vector3.ZERO
var _mode := "bust"

const LOOK_AT := {
	"portrait": Vector3(0, 1.62, 0),
	"bust": Vector3(0, 1.40, 0),
	"waist": Vector3(0, 1.0, 0),
	"full": Vector3(0, 0.9, 0),
}


func _ready() -> void:
	_build_rig()
	_build_camera()
	_build_lights()
	timeline.set_profile(viseme_profile)
	playback.setup(self)
	playback.set_sample_rate(24000)
	set_camera_mode("bust", true)


func _build_rig() -> void:
	rig = EngineeringRig.new()
	rig.set_name("EngineeringRig")
	add_child(rig)
	rig.build()
	rig.reset_pose()


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.set_name("Camera3D")
	camera.fov = 40.0
	add_child(camera)
	camera.current = true


func _build_lights() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.03, 0.09)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.35, 0.30, 0.50)
	e.ambient_light_energy = 1.2
	env.environment = e
	add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-30, 0, 0)
	key.light_energy = 2.5
	key.light_color = Color(1.0, 0.95, 1.0)
	add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(0, 40, 0)
	fill.light_energy = 1.2
	fill.light_color = Color(0.7, 0.75, 1.0)
	add_child(fill)

	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-15, 150, 0)
	rim.light_energy = 1.1
	rim.light_color = Color(0.25, 0.85, 0.9)
	add_child(rim)


func setup_session(session: SpeechSession) -> void:
	session.segments_ready.connect(_on_segments_ready)
	session.state_changed.connect(_on_session_state)


func set_camera_mode(mode: String, immediate: bool = false) -> void:
	if not rig.camera_anchors.has(mode):
		return
	_mode = mode
	var anchor: Marker3D = rig.camera_anchors[mode]
	_camera_target_pos = anchor.global_position
	_camera_look = LOOK_AT.get(mode, Vector3(0, 1.2, 0))
	if immediate:
		camera.global_position = _camera_target_pos
	camera_mode_changed.emit(mode)


func _on_segments_ready(segments: Array) -> void:
	if segments.is_empty():
		return
	for seg in segments:
		timeline.add_segment(seg)
	var gen: int = segments[0].generation if segments[0] is SpeechSegment else 0
	playback.play(segments, gen)


func _on_session_state(turn: Turn) -> void:
	if turn.state == Turn.State.THINKING or turn.state == Turn.State.INTERRUPTED or turn.state == Turn.State.ERROR:
		playback.stop()
		timeline.clear()
		director.set_expression("neutral")
		director.set_viseme_weights({})


func _process(delta: float) -> void:
	director.advance(delta)

	# Speech layer from the playback sample clock (authority).
	if playback.is_playing():
		var sample := playback.current_sample()
		director.set_viseme_weights(timeline.weights_at(sample))
	else:
		director.set_viseme_weights({})

	# Compose and apply morphs (single owner per channel, clamped).
	var morphs := director.compute_morphs()
	for m in morphs:
		rig.set_morph(str(m), float(morphs[m]))

	_apply_bones()
	_update_camera(delta)


func _apply_bones() -> void:
	# Breathing (owner: chest/spine).
	var breath := director.breathing_phase() * director.breathing_amplitude_deg()
	rig.set_bone_rotation_deg("Chest", Vector3.RIGHT, breath)
	rig.set_bone_rotation_deg("Spine", Vector3.RIGHT, breath * 0.5)

	# Gaze (owner: head + eyes) + gesture combined into a single head pose.
	var gaze := _gaze_angles("Head", camera.global_position)
	var g := director.gesture_bone_deltas()
	var pitch := gaze.y + deg_to_rad(g.get("head_pitch_deg", 0.0))
	var yaw := gaze.x + deg_to_rad(g.get("head_yaw_deg", 0.0))
	var roll := deg_to_rad(g.get("head_roll_deg", 0.0))
	var head_q := Quaternion(Vector3.UP, yaw) * Quaternion(Vector3.RIGHT, pitch) * Quaternion(Vector3.FORWARD, roll)
	rig.set_bone_pose_rotation_quat("Head", head_q)

	# Eyes (owner: eyes) — converge on the camera.
	for bone in ["Eye.L", "Eye.R"]:
		var eg := _gaze_angles(bone, camera.global_position)
		var ey := clampf(eg.x, -0.5, 0.5)
		var ep := clampf(eg.y, -0.3, 0.3)
		rig.set_bone_pose_rotation_quat(bone, Quaternion(Vector3.UP, ey) * Quaternion(Vector3.RIGHT, ep))

	# Arm raise (owner: upper arms) for gestures.
	var arm := deg_to_rad(g.get("arm_raise_deg", 0.0))
	if abs(arm) > 0.0001:
		rig.set_bone_rotation("UpperArm.R", Vector3.FORWARD, arm)


func _gaze_angles(bone: String, target: Vector3) -> Vector2:
	var idx: int = int(rig._bone_index.get(bone, -1))
	if idx < 0:
		return Vector2.ZERO
	var gpose: Transform3D = rig.skeleton.get_bone_global_pose(idx)
	var world_dir := (target - gpose.origin).normalized()
	var local_dir := gpose.basis.inverse() * world_dir
	var yp := GazeSolver.yaw_pitch(local_dir)
	return GazeSolver.clamp_angles(yp.x, yp.y, deg_to_rad(30.0), deg_to_rad(20.0))


func _update_camera(delta: float) -> void:
	if not is_instance_valid(camera):
		return
	camera.global_position = camera.global_position.lerp(_camera_target_pos, minf(1.0, delta * 6.0))
	camera.look_at(_camera_look, Vector3.UP)
