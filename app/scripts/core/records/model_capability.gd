class_name ModelCapability
extends RefCounted
## Describes a model's capabilities with three-valued confidence:
## DISCOVERED (from profile docs), CONFIGURED (owner set it), VERIFIED (live test passed).

enum Level { DISCOVERED, CONFIGURED, VERIFIED }

var model_id: String = ""
var provider_id: String = ""
var display_name: String = ""

var text: int = Level.DISCOVERED
var vision: int = Level.DISCOVERED
var tools: int = Level.DISCOVERED
var structured_output: int = Level.DISCOVERED
var reasoning: int = Level.DISCOVERED
var image_generation: int = Level.DISCOVERED
var image_editing: int = Level.DISCOVERED
var audio: int = Level.DISCOVERED
var video: int = Level.DISCOVERED
var embeddings: int = Level.DISCOVERED

var context_limit: int = 0
var output_limit: int = 0
var supports_sampling: Array = []       # e.g. ["temperature","top_p","seed"]
var supports_streaming: bool = true
var native_options: Dictionary = {}     # versioned advanced panel, not flattened


static func level_name(level: int) -> String:
	match level:
		Level.VERIFIED:
			return "verified"
		Level.CONFIGURED:
			return "configured"
		_:
			return "discovered"


func capability_summary() -> Dictionary:
	return {
		"text": text,
		"vision": vision,
		"tools": tools,
		"structured_output": structured_output,
		"reasoning": reasoning,
		"image_generation": image_generation,
		"image_editing": image_editing,
		"audio": audio,
		"video": video,
		"embeddings": embeddings,
	}


func to_dict() -> Dictionary:
	var d := capability_summary()
	d["model_id"] = model_id
	d["provider_id"] = provider_id
	d["display_name"] = display_name
	d["context_limit"] = context_limit
	d["output_limit"] = output_limit
	d["supports_sampling"] = supports_sampling
	d["supports_streaming"] = supports_streaming
	d["native_options"] = native_options
	return d


static func from_dict(data: Dictionary) -> ModelCapability:
	var c := ModelCapability.new()
	c.model_id = str(data.get("model_id", ""))
	c.provider_id = str(data.get("provider_id", ""))
	c.display_name = str(data.get("display_name", c.model_id))
	c.text = int(data.get("text", Level.DISCOVERED))
	c.vision = int(data.get("vision", Level.DISCOVERED))
	c.tools = int(data.get("tools", Level.DISCOVERED))
	c.structured_output = int(data.get("structured_output", Level.DISCOVERED))
	c.reasoning = int(data.get("reasoning", Level.DISCOVERED))
	c.image_generation = int(data.get("image_generation", Level.DISCOVERED))
	c.image_editing = int(data.get("image_editing", Level.DISCOVERED))
	c.audio = int(data.get("audio", Level.DISCOVERED))
	c.video = int(data.get("video", Level.DISCOVERED))
	c.embeddings = int(data.get("embeddings", Level.DISCOVERED))
	c.context_limit = int(data.get("context_limit", 0))
	c.output_limit = int(data.get("output_limit", 0))
	c.supports_sampling = data.get("supports_sampling", [])
	c.supports_streaming = bool(data.get("supports_streaming", true))
	c.native_options = data.get("native_options", {})
	return c
