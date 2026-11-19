extends CanvasLayer

signal dialogue_finished

@onready var speaker_label: Label = $Panel/VBox/Speaker
@onready var text_label: Label = $Panel/VBox/Text
@onready var next_button: Button = $Panel/VBox/NextBtn
@onready var portrait_rect: TextureRect = $Portrait

var _lines: Array = []
var _index := 0
var _voice: String = ""
var _talk_node: Node = null
var _bounce_tween: Tween

func _ready() -> void:
	add_to_group("modal_panel")
	layer = 95
	hide()
	next_button.pressed.connect(_on_next_pressed)
	UiStyle.set_button_icon(next_button, "play", UiStyle.INK, 20)
	next_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		_on_next_pressed()
		get_viewport().set_input_as_handled()

func show_dialogue(speaker: String, lines: Array, portrait: Texture2D = null, voice: String = "", talk_node: Node = null) -> void:
	if lines.is_empty():
		return
	# {p} = nombre del personaje que se juega (Aby o Josmar)
	_lines = []
	for l in lines:
		_lines.append(str(l).replace("{p}", GameManager.player_name()))
	_index = 0
	_voice = voice
	_talk_node = talk_node
	speaker_label.text = speaker
	portrait_rect.texture = portrait
	portrait_rect.visible = portrait != null
	_show_line()
	_start_bounce()
	show()

func _show_line() -> void:
	text_label.text = _lines[_index]
	if _voice != "":
		AudioManager.play_named(_voice)

func _start_bounce() -> void:
	_stop_bounce()
	if _talk_node == null or not is_instance_valid(_talk_node):
		return
	_talk_node.set_meta("_dlg_base_scale", _talk_node.scale)
	_bounce_tween = create_tween().set_loops()
	var base: Vector2 = _talk_node.scale
	_bounce_tween.tween_property(_talk_node, "scale", base * Vector2(0.97, 1.05), 0.18).set_trans(Tween.TRANS_SINE)
	_bounce_tween.tween_property(_talk_node, "scale", base, 0.18).set_trans(Tween.TRANS_SINE)

func _stop_bounce() -> void:
	if _bounce_tween:
		_bounce_tween.kill()
		_bounce_tween = null
	if _talk_node and is_instance_valid(_talk_node) and _talk_node.has_meta("_dlg_base_scale"):
		_talk_node.scale = _talk_node.get_meta("_dlg_base_scale")

func _on_next_pressed() -> void:
	AudioManager.play_named("click")
	_index += 1
	if _index >= _lines.size():
		hide()
		portrait_rect.hide()
		_stop_bounce()
		_talk_node = null
		dialogue_finished.emit()
		return
	_show_line()
