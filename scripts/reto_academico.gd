extends Area2D

## Dónde queda la silla respecto a esta zona (el jugador se sienta ahí).
@export var seat_offset: Vector2 = Vector2(0, 48)

@export var challenge_id: String = "reto_escuela_1"
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
	if GameManager.is_challenge_completed(challenge_id):
		return
	_used = true
	if body.has_method("sit_at"):
		body.sit_at(global_position + seat_offset)
	elif body.has_method("face_board"):
		body.face_board()
	var q = QuestionBank.get_random_question()
	if q:
		_question_panel.show_question(q)
	else:
		_used = false

func _on_question_finished(was_correct: bool, points: int) -> void:
	if not _used:
		return
	if was_correct:
		GameManager.complete_challenge(challenge_id)
		print("Firma obtenida (%s). Total firmas: %s" % [challenge_id, GameManager.get_firmas_count()])
	else:
		_used = false
		print("Respuesta incorrecta, podés volver a intentar el reto.")
