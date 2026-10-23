class_name ProviderAdapter
extends RefCounted
## Protocol adapter interface (ADR-003). Named service profiles supply base URL/auth/model
## facts; adapters implement the wire protocol. Implementations must never block the render
## loop and must support cancellation through `is_cancelled`.

## Build a chat-completions request. Returns { url, headers (Array of Strings), body (String) }.
func build_chat_request(messages: Array, options: Dictionary) -> Dictionary:
	return {}


## Stream a chat completion. `on_record` is called with parsed records (see ChatStreamParser).
## `is_cancelled` is a Callable returning bool; when true the stream aborts promptly.
## Returns a summary Dictionary { status, error, model, usage }.
func stream_chat(messages: Array, options: Dictionary, on_record: Callable, is_cancelled: Callable) -> Dictionary:
	return {"status": "not_implemented", "error": "base adapter"}
