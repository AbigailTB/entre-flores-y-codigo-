extends Area2D

## Dónde queda la silla respecto a esta zona (el jugador se sienta ahí).
@export var seat_offset: Vector2 = Vector2(0, 142)

@export var question_panel_path: NodePath
@export var code_bug_panel_path: NodePath

var _question_panel: Control
var _code_bug_panel: Node
var _used := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_question_panel = get_node(question_panel_path)
	_code_bug_panel = get_node(code_bug_panel_path)
	_question_panel.question_finished.connect(_on_question_finished)
	_question_panel.question_cancelled.connect(func(): _used = false)
	_code_bug_panel.finished.connect(_on_bug_finished)

func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player"):
		return
	_used = true
	if body.has_method("sit_at"):
		body.sit_at(global_position + seat_offset)
	elif body.has_method("face_board"):
		body.face_board()
	if randi() % 2 == 0:
		var q = QuestionBank.get_random_question()
		if q:
			_question_panel.show_question(q)
		else:
			_used = false
	else:
		var bug = CodeBugBank.get_random_bug()
		if bug:
			_code_bug_panel.mostrar_bug(bug)
		else:
			_used = false

func _on_question_finished(_was_correct: bool, _points: int) -> void:
	_used = false

func _on_bug_finished(_was_correct: bool) -> void:
	_used = false
