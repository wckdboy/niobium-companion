class_name ProviderProfile
extends RefCounted
## A named service profile: base URL, auth mode, model list, capability facts.
## Protocol adapters are separate from profiles (ADR-003). No secrets live here;
## credentials are referenced via CredentialRef.

enum AuthMode { NONE, API_KEY, CUSTOM_HEADER, OAUTH }

var id: String = ""
var name: String = ""
var protocol: String = "openai_compatible"   # adapter key
var base_url: String = ""
var auth_mode: int = AuthMode.API_KEY
var auth_header: String = "Authorization"     # e.g. "Authorization", "x-api-key"
var auth_prefix: String = "Bearer "           # "", "Bearer ", etc.
var oauth_scope: String = ""
var models: Array = []                        # Array[ModelCapability]
var default_model: String = ""
var extra_headers: Dictionary = {}
var meta: Dictionary = {}


static func new_id() -> String:
	return "prov_%d_%d" % [Time.get_ticks_msec(), randi() % 0x7fffffff]


func credential_ref() -> CredentialRef:
	return CredentialRef.for_provider(id)


func to_dict() -> Dictionary:
	var models := []
	for m in models:
		models.append((m as ModelCapability).to_dict())
	return {
		"id": id,
		"name": name,
		"protocol": protocol,
		"base_url": base_url,
		"auth_mode": auth_mode,
		"auth_header": auth_header,
		"auth_prefix": auth_prefix,
		"oauth_scope": oauth_scope,
		"models": models,
		"default_model": default_model,
		"extra_headers": extra_headers,
		"meta": meta,
	}


static func from_dict(data: Dictionary) -> ProviderProfile:
	var p := ProviderProfile.new()
	p.id = str(data.get("id", new_id()))
	p.name = str(data.get("name", p.id))
	p.protocol = str(data.get("protocol", "openai_compatible"))
	p.base_url = str(data.get("base_url", ""))
	p.auth_mode = int(data.get("auth_mode", AuthMode.API_KEY))
	p.auth_header = str(data.get("auth_header", "Authorization"))
	p.auth_prefix = str(data.get("auth_prefix", "Bearer "))
	p.oauth_scope = str(data.get("oauth_scope", ""))
	p.default_model = str(data.get("default_model", ""))
	p.extra_headers = data.get("extra_headers", {})
	p.meta = data.get("meta", {})
	var models := []
	for m in data.get("models", []):
		models.append(ModelCapability.from_dict(m))
	p.models = models
	return p


func get_model(model_id: String) -> ModelCapability:
	for m in models:
		if (m as ModelCapability).model_id == model_id:
			return m
	return null
