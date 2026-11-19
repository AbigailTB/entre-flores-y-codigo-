extends Control

signal finished(was_correct: bool)

@onready var code_list: VBoxContainer = $Card/VBox/CodeList
@onready var pista_label: Label = $Card/VBox/PistaLabel
@onready var feedback_label: Label = $Card/VBox/Feedback
@onready var continue_button: Button = $Card/VBox/ContinueBtn

var _bug
var _answered := false
var _last_correct := false

func _ready() -> void:
	add_to_group("modal_panel")
	hide()
	continue_button.pressed.connect(_on_continue_pressed)
	continue_button.hide()
	UiUtil.add_close_button($Card, cancel)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		cancel()
		get_viewport().set_input_as_handled()

## Cerrar con la X o Esc: no cuenta como acierto, se puede volver a intentar.
func cancel() -> void:
	if not visible:
		return
	AudioManager.play_named("click")
	if _answered:
		_on_continue_pressed()
		return
	hide()
	finished.emit(false)

func mostrar_bug(bug) -> void:
	_bug = bug
	_answered = false
	feedback_label.text = ""
	continue_button.hide()
	pista_label.text = "Pista: %s" % bug.pista

	for child in code_list.get_children():
		child.queue_free()

	for i in bug.codigo.size():
		var btn := Button.new()
		btn.text = bug.codigo[i]
		btn.custom_minimum_size = Vector2(0, 44)
		btn.add_theme_font_size_override("font_size", 18)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_line_pressed.bind(i, btn))
		code_list.add_child(btn)

	show()

func _on_line_pressed(index: int, btn: Button) -> void:
	if _answered:
		return
	_answered = true
	_last_correct = index == _bug.linea_incorrecta

	for child in code_list.get_children():
		child.disabled = true

	AudioManager.play_named("correcto" if _last_correct else "incorrecto")
	if _last_correct:
		btn.modulate = Color(0.4, 0.9, 0.5)
		feedback_label.text = "¡Encontraste el error! " + _bug.explicacion
	else:
		btn.modulate = Color(0.95, 0.4, 0.4)
		var correct_btn: Button = code_list.get_child(_bug.linea_incorrecta)
		correct_btn.modulate = Color(0.4, 0.9, 0.5)
		feedback_label.text = "Esa línea está bien. " + _bug.explicacion

	continue_button.show()

func _on_continue_pressed() -> void:
	hide()
	finished.emit(_last_correct)
