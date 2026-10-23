class_name ProviderCatalog
extends RefCounted
## Named service profiles (ADR-003). Endpoint URLs below were checked against the providers'
## documentation on 2026-10-23 (see meta.fetched_at). "verified_endpoint" means the URL was
## confirmed from docs; "live_tested" means an actual credentialed call succeeded (none yet).
## Model lists are deliberately minimal — models are discoverable at runtime, not hard-coded.

const OPENAI_COMPATIBLE := "openai_compatible"
const ANTHROPIC := "anthropic"
const GEMINI := "gemini"


static func deepseek() -> ProviderProfile:
	var p := ProviderProfile.new()
	p.id = "deepseek"
	p.name = "DeepSeek"
	p.protocol = OPENAI_COMPATIBLE
	p.base_url = "https://api.deepseek.com"
	p.auth_mode = ProviderProfile.AuthMode.API_KEY
	p.default_model = "deepseek-flash"
	p.models = [
		_model("deepseek-flash", p.id, {"text": ModelCapability.Level.DISCOVERED}),
		_model("deepseek-v4-pro", p.id, {"text": ModelCapability.Level.DISCOVERED, "reasoning": ModelCapability.Level.DISCOVERED}),
	]
	p.meta = {
		"verified_endpoint": true, "fetched_at": 20261023,
		"notes": "OpenAI-compatible. Anthropic-compatible at /anthropic. reasoning summary via delta.reasoning_content.",
	}
	return p


static func abliteration() -> ProviderProfile:
	var p := ProviderProfile.new()
	p.id = "abliteration"
	p.name = "Abliteration.ai"
	p.protocol = OPENAI_COMPATIBLE
	p.base_url = "https://api.abliteration.ai/v1"
	p.auth_mode = ProviderProfile.AuthMode.API_KEY
	p.default_model = "abliterated-model"
	p.models = [
		_model("abliterated-model", p.id, {"text": ModelCapability.Level.DISCOVERED}),
	]
	p.meta = {
		"verified_endpoint": true, "fetched_at": 20261023,
		"notes": "OpenAI SDK base_url https://api.abliteration.ai/v1; Anthropic SDK at https://api.abliteration.ai. Model ids discoverable from docs.",
	}
	return p


static func opencode_go() -> ProviderProfile:
	var p := ProviderProfile.new()
	p.id = "opencode_go"
	p.name = "OpenCode Go"
	p.protocol = OPENAI_COMPATIBLE
	p.base_url = "https://opencode.ai/inference/go/openai/v1"
	p.auth_mode = ProviderProfile.AuthMode.API_KEY
	p.default_model = "deepseek-v4-pro"
	p.models = [
		_model("deepseek-v4-pro", p.id, {"text": ModelCapability.Level.DISCOVERED}),
		_model("deepseek-v4.1-flash", p.id, {"text": ModelCapability.Level.DISCOVERED}),
	]
	p.extra_headers = {}  # caller adds x-opencode-session + a distinct User-Agent
	p.meta = {
		"verified_endpoint": true, "fetched_at": 20261023,
		"notes": "Console subscription + API key. OpenAI-compatible /chat/completions; some models use /responses or Anthropic/Google paths. Sends x-opencode-session header + non-generic User-Agent. Designed for coding agents; personal use per owner's own subscription.",
	}
	return p


static func openai() -> ProviderProfile:
	var p := ProviderProfile.new()
	p.id = "openai"
	p.name = "OpenAI"
	p.protocol = OPENAI_COMPATIBLE
	p.base_url = "https://api.openai.com/v1"
	p.auth_mode = ProviderProfile.AuthMode.API_KEY
	p.default_model = ""
	p.meta = {"verified_endpoint": true, "fetched_at": 20261023, "notes": "Also exposes Responses protocol (separate adapter)."}
	return p


static func xai() -> ProviderProfile:
	var p := ProviderProfile.new()
	p.id = "xai"
	p.name = "xAI"
	p.protocol = OPENAI_COMPATIBLE
	p.base_url = "https://api.x.ai/v1"
	p.auth_mode = ProviderProfile.AuthMode.API_KEY
	p.meta = {"verified_endpoint": true, "fetched_at": 20261023}
	return p


static func openrouter() -> ProviderProfile:
	var p := ProviderProfile.new()
	p.id = "openrouter"
	p.name = "OpenRouter"
	p.protocol = OPENAI_COMPATIBLE
	p.base_url = "https://openrouter.ai/api/v1"
	p.auth_mode = ProviderProfile.AuthMode.API_KEY
	p.extra_headers = {"HTTP-Referer": "https://niobium.local", "X-Title": "Niobium"}
	p.meta = {"verified_endpoint": true, "fetched_at": 20261023}
	return p


static func deepinfra() -> ProviderProfile:
	var p := ProviderProfile.new()
	p.id = "deepinfra"
	p.name = "DeepInfra"
	p.protocol = OPENAI_COMPATIBLE
	p.base_url = "https://api.deepinfra.com/v1/openai"
	p.auth_mode = ProviderProfile.AuthMode.API_KEY
	p.meta = {"verified_endpoint": true, "fetched_at": 20261023}
	return p


static func ollama() -> ProviderProfile:
	var p := ProviderProfile.new()
	p.id = "ollama"
	p.name = "Ollama (local)"
	p.protocol = OPENAI_COMPATIBLE
	p.base_url = "http://localhost:11434/v1"
	p.auth_mode = ProviderProfile.AuthMode.NONE
	p.meta = {"verified_endpoint": true, "fetched_at": 20261023, "local": true}
	return p


static func llama_cpp() -> ProviderProfile:
	var p := ProviderProfile.new()
	p.id = "llama_cpp"
	p.name = "llama.cpp server (local)"
	p.protocol = OPENAI_COMPATIBLE
	p.base_url = "http://localhost:8080/v1"
	p.auth_mode = ProviderProfile.AuthMode.NONE
	p.meta = {"verified_endpoint": true, "fetched_at": 20261023, "local": true}
	return p


static func lm_studio() -> ProviderProfile:
	var p := ProviderProfile.new()
	p.id = "lm_studio"
	p.name = "LM Studio (local)"
	p.protocol = OPENAI_COMPATIBLE
	p.base_url = "http://localhost:1234/v1"
	p.auth_mode = ProviderProfile.AuthMode.NONE
	p.meta = {"verified_endpoint": true, "fetched_at": 20261023, "local": true}
	return p


static func vllm() -> ProviderProfile:
	var p := ProviderProfile.new()
	p.id = "vllm"
	p.name = "vLLM (local)"
	p.protocol = OPENAI_COMPATIBLE
	p.base_url = "http://localhost:8000/v1"
	p.auth_mode = ProviderProfile.AuthMode.NONE
	p.meta = {"verified_endpoint": true, "fetched_at": 20261023, "local": true}
	return p


static func anthropic() -> ProviderProfile:
	var p := ProviderProfile.new()
	p.id = "anthropic"
	p.name = "Anthropic"
	p.protocol = ANTHROPIC
	p.base_url = "https://api.anthropic.com"
	p.auth_mode = ProviderProfile.AuthMode.API_KEY
	p.meta = {"verified_endpoint": true, "fetched_at": 20261023, "notes": "Requires Anthropic messages adapter."}
	return p


static func gemini() -> ProviderProfile:
	var p := ProviderProfile.new()
	p.id = "gemini"
	p.name = "Google Gemini"
	p.protocol = GEMINI
	p.base_url = "https://generativelanguage.googleapis.com/v1beta"
	p.auth_mode = ProviderProfile.AuthMode.API_KEY
	p.meta = {"verified_endpoint": true, "fetched_at": 20261023, "notes": "Requires Gemini native adapter."}
	return p


## All built-in profiles, keyed by id.
static func all() -> Dictionary:
	return {
		"deepseek": deepseek(),
		"abliteration": abliteration(),
		"opencode_go": opencode_go(),
		"openai": openai(),
		"xai": xai(),
		"openrouter": openrouter(),
		"deepinfra": deepinfra(),
		"ollama": ollama(),
		"llama_cpp": llama_cpp(),
		"lm_studio": lm_studio(),
		"vllm": vllm(),
		"anthropic": anthropic(),
		"gemini": gemini(),
	}


static func _model(id: String, provider_id: String, caps: Dictionary) -> ModelCapability:
	var m := ModelCapability.new()
	m.model_id = id
	m.provider_id = provider_id
	m.display_name = id
	if caps.has("text"):
		m.text = caps["text"]
	if caps.has("reasoning"):
		m.reasoning = caps["reasoning"]
	return m
