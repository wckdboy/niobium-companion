class_name CredentialRef
extends RefCounted
## A reference to a credential held in an OS keystore. Never carries the secret value.
## The `backend` field describes where the secret actually lives.

enum Backend { UNAVAILABLE, ANDROID_KEYSTORE, MACOS_KEYCHAIN, LINUX_SECRET_SERVICE, DEV_VAULT }

var provider_id: String = ""
var scope: String = "default"
var backend: int = Backend.UNAVAILABLE
var label: String = ""


static func for_provider(provider_id: String, scope: String = "default") -> CredentialRef:
	var r := CredentialRef.new()
	r.provider_id = provider_id
	r.scope = scope
	r.label = provider_id
	return r


func key() -> String:
	return "%s/%s" % [provider_id, scope]


func is_available() -> bool:
	return backend != Backend.UNAVAILABLE


func to_dict() -> Dictionary:
	return {
		"provider_id": provider_id,
		"scope": scope,
		"backend": backend,
		"label": label,
	}


static func from_dict(data: Dictionary) -> CredentialRef:
	var r := CredentialRef.new()
	r.provider_id = str(data.get("provider_id", ""))
	r.scope = str(data.get("scope", "default"))
	r.backend = int(data.get("backend", Backend.UNAVAILABLE))
	r.label = str(data.get("label", r.provider_id))
	return r
