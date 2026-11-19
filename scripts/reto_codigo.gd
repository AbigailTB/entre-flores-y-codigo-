extends Area2D

## Dónde queda la silla respecto a esta zona (el jugador se sienta ahí).
@export var seat_offset: Vector2 = Vector2(0, 48)

@export var challenge_id: String = "reto_escuela_2"
@export var code_bug_panel_path: NodePath

var _panel: Node
var _used := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_panel = get_node(code_bug_panel_path)
	_panel.finished.connect(_on_finished)

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
	var bug = CodeBugBank.get_random_bug()
	if bug:
		_panel.mostrar_bug(bug)
	else:
		_used = false

func _on_finished(was_correct: bool) -> void:
	if not _used:
		return
	if was_correct:
		GameManager.complete_challenge(challenge_id)
		print("Firma obtenida (%s). Total firmas: %s" % [challenge_id, GameManager.get_firmas_count()])
	else:
		_used = false
		print("No era esa línea, podés volver a intentarlo.")
