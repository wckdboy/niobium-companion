class_name HttpStreamClient
extends RefCounted
## Low-level non-blocking streaming HTTP(S) client built on HTTPClient. Used by provider
## adapters for SSE. Never blocks; callers pump `poll()` per frame. Emits raw body bytes via
## `on_chunk` so the adapter's SSE parser owns framing.

enum State { CONNECTING, RUNNING, DONE, ERROR }

var _client: HTTPClient = null
var _url := ""
var _scheme := "https"
var _host := ""
var _port := 443
var _path := "/"
var _method := HTTPClient.METHOD_POST
var _headers: Array = []
var _body := ""

var _connected := false
var _request_sent := false
var _response_started := false
var _status_code := 0
var _error := ""
var _redirects := 0
var _buf := PackedByteArray()


func open(url: String, headers: Array, body: String) -> void:
	_url = url
	_headers = headers
	_body = body
	_parse_url(url)
	_client = HTTPClient.new()
	var tls := TLSOptions.client() if _scheme == "https" else null
	var err := _client.connect_to_host(_host, _port, tls)
	if err != OK:
		_error = "connect_to_host failed: %s" % error_string(err)


func _parse_url(url: String) -> void:
	if url.begins_with("https://"):
		_scheme = "https"
		url = url.substr(8)
		_port = 443
	elif url.begins_with("http://"):
		_scheme = "http"
		url = url.substr(7)
		_port = 80
	var slash := url.find("/")
	var host_port := url
	if slash >= 0:
		host_port = url.substr(0, slash)
		_path = url.substr(slash)
		if _path == "":
			_path = "/"
	var colon := host_port.find(":")
	if colon >= 0:
		_host = host_port.substr(0, colon)
		_port = int(host_port.substr(colon + 1))
	else:
		_host = host_port


## Advance one non-blocking step. Calls on_chunk(bytes) with freshly read body bytes.
func poll(on_chunk: Callable, is_cancelled: Callable) -> int:
	if _client == null:
		return State.ERROR
	_client.poll()

	if not _connected:
		match _client.get_status():
			HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING:
				return State.CONNECTING
			HTTPClient.STATUS_CONNECTED:
				_connected = true
			HTTPClient.STATUS_CANT_CONNECT, HTTPClient.STATUS_CANT_RESOLVE, HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
				_error = "connection failed: %s" % _client.get_status()
				return State.ERROR
			_:
				return State.CONNECTING

	if not _request_sent:
		var err := _client.request(_method, _path, _headers, _body)
		if err != OK:
			_error = "request failed: %s" % error_string(err)
			return State.ERROR
		_request_sent = true
		return State.RUNNING

	# Response phase.
	if not _response_started and _client.has_response():
		_status_code = _client.get_response_code()
		_response_started = true
		# Follow a limited number of redirects.
		if _status_code in [301, 302, 303, 307, 308]:
			var location := _header_value("location")
			_redirects += 1
			if _redirects > 5:
				_error = "too many redirects"
				return State.ERROR
			_client.close()
			_connected = false
			_request_sent = false
			_response_started = false
			_open_from(location)
			return State.RUNNING

	# Read available body bytes.
	var chunk := _client.read_response_body_chunk()
	if chunk.size() > 0:
		_buf.append_array(chunk)
		if on_chunk.is_valid():
			on_chunk.call(chunk)

	if _client.get_status() == HTTPClient.STATUS_DISCONNECTED:
		if _status_code >= 400:
			_error = "HTTP %d: %s" % [_status_code, _buf.get_string_from_utf8().left(500)]
			return State.ERROR
		return State.DONE
	return State.RUNNING


func _open_from(location: String) -> void:
	# Resolve relative redirect against the previous URL.
	var resolved := location
	if not location.begins_with("http://") and not location.begins_with("https://"):
		resolved = "%s://%s%s" % [_scheme, _host, location if location.begins_with("/") else "/" + location]
	open(resolved, _headers, _body)


func _header_value(name: String) -> String:
	var headers: PackedStringArray = _client.get_response_headers()
	for h in headers:
		if h.begins_with(name + ":") or h.begins_with(name.to_lower() + ":"):
			return h.substr(h.find(":") + 1).strip_edges()
	return ""


func close() -> void:
	if _client != null:
		_client.close()


func status_code() -> int:
	return _status_code


func error_message() -> String:
	return _error
