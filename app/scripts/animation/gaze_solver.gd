class_name GazeSolver
extends RefCounted
## Pure gaze math: converts a local-space direction into yaw/pitch angles (forward = -Z),
## with clamping. Unit-tested; the stage applies the result to head/eye bones.

static func yaw_pitch(local_dir: Vector3) -> Vector2:
	var d := local_dir.normalized()
	var yaw := atan2(d.x, -d.z)
	var horizontal := Vector2(d.x, d.z).length()
	var pitch := atan2(d.y, horizontal)
	return Vector2(yaw, pitch)


static func clamp_angles(yaw: float, pitch: float, max_yaw: float, max_pitch: float) -> Vector2:
	return Vector2(clampf(yaw, -max_yaw, max_yaw), clampf(pitch, -max_pitch, max_pitch))
