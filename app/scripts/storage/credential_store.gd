class_name CredentialStore
extends RefCounted
## Resolves/keeps credentials in the OS keystore. In this build environment there is no
## device keystore, so the default backend is UNAVAILABLE (an explicit locked state) — there
## is no silent plaintext downgrade. An opt-in `DevVault` writes to a local file and is
## clearly marked insecure, for local development only.

var _backend: int = CredentialRef.Backend.UNAVAILABLE
var _dev_path := "user://dev_vault.json"
var _dev_enabled := false
var _dev_data: Dictionary = {}


func backend() -> int:
	return _backend


func is_available() -> bool:
	return _backend != CredentialRef.Backend.UNAVAILABLE


## Opt-in, clearly-insecure local vault for development on machines without a keystore.
func enable_dev_vault(path: String = "") -> void:
	if path != "":
		_dev_path = path
	_dev_enabled = true
	_backend = CredentialRef.Backend.DEV_VAULT
	_load_dev()


func set_credential(ref: CredentialRef, secret: String) -> Error:
	match _backend:
		CredentialRef.Backend.DEV_VAULT:
			_dev_data[ref.key()] = secret
			_save_dev()
			return OK
		_:
			push_error("CredentialStore: no secure backend available; credential not stored.")
			return ERR_UNAVAILABLE


func get_credential(ref: CredentialRef) -> String:
	match _backend:
		CredentialRef.Backend.DEV_VAULT:
			return str(_dev_data.get(ref.key(), ""))
		_:
			return ""


func has_credential(ref: CredentialRef) -> bool:
	return get_credential(ref) != ""


func delete_credential(ref: CredentialRef) -> void:
	if _backend == CredentialRef.Backend.DEV_VAULT:
		_dev_data.erase(ref.key())
		_save_dev()


func _load_dev() -> void:
	_dev_data = {}
	if FileAccess.file_exists(_dev_path):
		var f := FileAccess.open(_dev_path, FileAccess.READ)
		if f != null:
			var parsed = JSON.parse_string(f.get_as_text())
			f.close()
			if typeof(parsed) == TYPE_DICTIONARY:
				_dev_data = parsed


func _save_dev() -> void:
	var f := FileAccess.open(_dev_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(_dev_data))
		f.close()
