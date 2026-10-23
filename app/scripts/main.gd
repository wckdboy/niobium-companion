extends Node
## Niobium application entry point. Wires the companion stage, chat UI and the service layer
## (store, credentials, provider adapter, TTS, speech session). Defaults to an offline scripted
## demo so the full animated-conversation pipeline runs without credentials; real providers are
## configured by swapping the adapter (see scripts/providers/provider_catalog.gd).

var store: Store
var credentials: CredentialStore
var session: SpeechSession
var stage: CompanionStage
var chat: ChatUI
var _assistant_started := false

const SYSTEM_PROMPT := "You are Niobium, a private AI companion. Warm, mature, witty and responsive. " + \
	"You help create, discuss, plan and use tools when allowed. Keep responses natural and concise."


func _ready() -> void:
	_setup_store()
	_setup_session()
	_setup_scene()
	_setup_ui()


func _setup_store() -> void:
	store = Store.new("user://data")
	store.register_migration(0, func(_v): pass)
	store.open()
	credentials = CredentialStore.new()
	# Keystore is UNAVAILABLE in this environment; see docs/ADR-003. No plaintext downgrade.


func _setup_session() -> void:
	session = SpeechSession.new()
	# Offline development demo. Swap for a live adapter once the owner configures a provider:
	#   var profile = ProviderCatalog.deepseek()
	#   session.adapter = OpenAICompatibleAdapter.new(profile)
	session.adapter = ScriptedAdapter.new("Hello — I am Niobium, your private companion. " + \
		"Ask me anything, and let's make something together.")
	session.tts = TestTTS.new()
	session.store = store
	session.credentials = credentials
	session.system_prompt = SYSTEM_PROMPT
	session.load_conversation()


func _setup_scene() -> void:
	stage = CompanionStage.new()
	stage.set_name("CompanionStage")
	add_child(stage)
	stage.setup_session(session)


func _setup_ui() -> void:
	var layer := CanvasLayer.new()
	layer.set_name("UI")
	add_child(layer)
	chat = ChatUI.new()
	chat.set_name("ChatUI")
	chat.set_anchors_preset(Control.PRESET_FULL_RECT)
	chat.offset_left = 640
	chat.offset_top = 0
	chat.offset_right = 0
	chat.offset_bottom = 0
	layer.add_child(chat)

	chat.send_requested.connect(_on_send)
	chat.interrupt_requested.connect(_on_interrupt)
	chat.camera_mode_requested.connect(func(mode): stage.set_camera_mode(mode))
	session.text_delta.connect(_on_text_delta)
	session.state_changed.connect(_on_state_changed)
	session.turn_finished.connect(_on_turn_finished)


func _on_send(text: String) -> void:
	_assistant_started = false
	session.begin_turn(text)


func _on_interrupt() -> void:
	session.interrupt()


func _on_text_delta(_turn_id: String, delta: String) -> void:
	if not _assistant_started:
		chat.begin_assistant_message()
		_assistant_started = true
	chat.append_delta(delta)


func _on_state_changed(turn: Turn) -> void:
	match turn.state:
		Turn.State.THINKING:
			chat.set_status("thinking…")
		Turn.State.SPEAKING:
			chat.set_status("speaking")
		Turn.State.INTERRUPTED:
			chat.set_status("interrupted")
		Turn.State.ERROR:
			chat.set_status("error")
		Turn.State.COMPLETED:
			chat.set_status("idle")


func _on_turn_finished(_turn: Turn) -> void:
	if _assistant_started:
		chat.finish_assistant_message()
		_assistant_started = false
	chat.set_status("idle")
