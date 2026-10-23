class_name ChatUI
extends Control
## Chat panel: message list (streaming), input, interrupt and camera-mode controls. Emits
## signals the app wires to the SpeechSession/CompanionStage. Plain-text streaming now;
## markdown/code highlighting is a later gate (see docs/CHECKLIST.md).

signal send_requested(text: String)
signal interrupt_requested()
signal camera_mode_requested(mode: String)

var _messages: VBoxContainer
var _scroll: ScrollContainer
var _input: LineEdit
var _status: Label
var _assistant_label: RichTextLabel
var _stop_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()


func _build() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 0
	panel.offset_top = 0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.045, 0.12, 0.94)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "Niobium"
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)
	_status = Label.new()
	_status.text = "idle"
	_status.add_theme_color_override("font_color", Color(0.6, 0.9, 0.9))
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_status)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_scroll)
	_messages = VBoxContainer.new()
	_messages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_messages.add_theme_constant_override("separation", 8)
	_scroll.add_child(_messages)

	var input_row := HBoxContainer.new()
	root.add_child(input_row)
	_input = LineEdit.new()
	_input.placeholder_text = "Say something…"
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.text_submitted.connect(_on_submit)
	input_row.add_child(_input)

	var send := Button.new()
	send.text = "Send"
	send.pressed.connect(_on_submit_button)
	input_row.add_child(send)

	_stop_button = Button.new()
	_stop_button.text = "Stop"
	_stop_button.pressed.connect(func(): interrupt_requested.emit())
	input_row.add_child(_stop_button)

	var cam_row := HBoxContainer.new()
	root.add_child(cam_row)
	for mode in RigProfile.CAMERA_ANCHORS:
		var b := Button.new()
		b.text = mode
		b.pressed.connect(func(): camera_mode_requested.emit(mode))
		cam_row.add_child(b)


func _on_submit(_text: String) -> void:
	_on_submit_button()


func _on_submit_button() -> void:
	var text := _input.text.strip_edges()
	if text.is_empty():
		return
	_input.clear()
	add_user_message(text)
	send_requested.emit(text)


func add_user_message(text: String) -> void:
	_add_bubble(text, "user")


func begin_assistant_message() -> void:
	_assistant_label = _new_bubble("assistant")
	_assistant_label.text = ""


func append_delta(text: String) -> void:
	if _assistant_label == null or not is_instance_valid(_assistant_label):
		begin_assistant_message()
	_assistant_label.append_text(text)


func finish_assistant_message() -> void:
	_assistant_label = null
	_scroll_to_bottom()


func set_status(text: String) -> void:
	_status.text = text


func _add_bubble(text: String, who: String) -> RichTextLabel:
	var l := _new_bubble(who)
	l.text = text
	_scroll_to_bottom()
	return l


func _new_bubble(who: String) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 15)
	if who == "user":
		l.add_theme_color_override("default_color", Color(0.75, 0.9, 1.0))
	else:
		l.add_theme_color_override("default_color", Color(0.9, 0.85, 0.98))
	_messages.add_child(l)
	return l


func _scroll_to_bottom() -> void:
	# Defer so layout settles before scrolling.
	call_deferred("_do_scroll")


func _do_scroll() -> void:
	if _scroll != null:
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)
