extends Area2D

const CHALLENGE_ID := "reto_final"
const RECOMPENSA := 100
const FIRMAS_REQUERIDAS := 3

@export var panel_path: NodePath

var _panel: Node
var _used := false
var _flora_portrait: Texture2D = preload("res://assets/portraits/flora_normal.png")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_panel = get_node(panel_path)
	_panel.completado.connect(_on_completado)
	_panel.closed.connect(_on_panel_closed)

func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player"):
		return
	if GameManager.is_challenge_completed(CHALLENGE_ID):
		return
	_used = true
	var firmas := GameManager.get_firmas_count()
	if firmas < FIRMAS_REQUERIDAS:
		DialogueBox.show_dialogue("Doña Flora", [
			"Todavía no puedes registrar el proyecto final.",
			"Necesitas al menos %d firmas y tienes %d. ¡Sigue con tus retos en la escuela y la florería!" % [FIRMAS_REQUERIDAS, firmas],
		], _flora_portrait)
		return
	_panel.abrir()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and not _panel.visible:
		_used = false

func _on_panel_closed() -> void:
	_used = false

func _on_completado() -> void:
	GameManager.add_money(RECOMPENSA)
	AudioManager.play_named("dinero")
	GameManager.complete_challenge(CHALLENGE_ID)
	await SignatureReward.closed_popup
	VictoryPanel.mostrar_final()
