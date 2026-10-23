class_name RigProfile
extends RefCounted
## Declares the bone/morph/camera contract a character must satisfy. A drop-in glTF/VRM maps
## its own names to these conventions via its profile; unknown bones/morphs are reported, not
## guessed.

const HUMAN_BONES := [
	"Hips", "Spine", "Chest", "Neck", "Head",
	"Shoulder.L", "Shoulder.R", "UpperArm.L", "UpperArm.R",
	"LowerArm.L", "LowerArm.R", "Hand.L", "Hand.R",
	"UpperLeg.L", "UpperLeg.R", "LowerLeg.L", "LowerLeg.R",
	"Foot.L", "Foot.R", "Eye.L", "Eye.R",
]

const BASE_MORPHS := [
	"jaw_open", "lips_wide", "lips_round", "lips_f", "lips_close",
	"blink_L", "blink_R", "brow_raise", "smile", "frown",
]

const CAMERA_ANCHORS := ["portrait", "bust", "waist", "full"]

var id: String = ""
var name: String = ""
var asset_id: String = ""
var license: String = ""
var provenance: String = ""
var rights_cleared: bool = false
var bones: Array = []          # required bone names (subset of HUMAN_BONES)
var morphs: Array = []         # required morph channels (subset of BASE_MORPHS)
var camera_anchors: Array = [] # subset of CAMERA_ANCHORS
var viseme_profile: VisemeProfile


func to_dict() -> Dictionary:
	var d := {
		"id": id,
		"name": name,
		"asset_id": asset_id,
		"license": license,
		"provenance": provenance,
		"rights_cleared": rights_cleared,
		"bones": bones,
		"morphs": morphs,
		"camera_anchors": camera_anchors,
	}
	if viseme_profile != null:
		d["visemes"] = viseme_profile._map
	return d


static func from_dict(data: Dictionary) -> RigProfile:
	var p := RigProfile.new()
	p.id = str(data.get("id", ""))
	p.name = str(data.get("name", p.id))
	p.asset_id = str(data.get("asset_id", ""))
	p.license = str(data.get("license", ""))
	p.provenance = str(data.get("provenance", ""))
	p.rights_cleared = bool(data.get("rights_cleared", false))
	p.bones = data.get("bones", [])
	p.morphs = data.get("morphs", [])
	p.camera_anchors = data.get("camera_anchors", [])
	p.viseme_profile = VisemeProfile.default_profile()
	if data.has("visemes") and typeof(data["visemes"]) == TYPE_DICTIONARY:
		for v in data["visemes"]:
			p.viseme_profile.set_weights(str(v), data["visemes"][v])
	return p
