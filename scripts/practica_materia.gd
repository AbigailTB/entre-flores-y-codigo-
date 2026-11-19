extends Area2D

## Dónde queda la silla respecto a esta zona (el jugador se sienta ahí).
@export var seat_offset: Vector2 = Vector2(0, -14)

@export var materia: String = ""
@export var question_panel_path: NodePath

var _question_panel: Control
var _used := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_question_panel = get_node(question_panel_path)
	_question_panel.question_finished.connect(_on_question_finished)
	_question_panel.question_cancelled.connect(func(): _used = false)

func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player"):
		return
	_used = true
	if body.has_method("sit_at"):
		body.sit_at(global_position + seat_offset)
	elif body.has_method("face_board"):
		body.face_board()
	var q = QuestionBank.get_random_question_by_subject(materia)
	if q:
		_question_panel.show_question(q, "Práctica")
	else:
		_used = false

func _on_question_finished(_was_correct: bool, _points: int) -> void:
	_used = false
