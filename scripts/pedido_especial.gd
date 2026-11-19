extends Area2D

@export var challenge_id: String = "reto_floreria_1"
@export var bouquet_panel_path: NodePath

const REQS := [
	{"id": "rosa_roja", "nombre": "Rosa roja", "requerido": 3, "actual": 0},
	{"id": "margarita", "nombre": "Margarita", "requerido": 2, "actual": 0},
	{"id": "girasol", "nombre": "Girasol", "requerido": 2, "actual": 0},
]
const RECOMPENSA := 80

var _panel: Node
var _used := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_panel = get_node(bouquet_panel_path)
	_panel.closed.connect(_on_closed)
	_panel.solved.connect(_on_solved)

func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player"):
		return
	if GameManager.is_challenge_completed(challenge_id):
		return
	_used = true
	_panel.abrir_pedido(REQS, RECOMPENSA, "🌟 Pedido Especial de Doña Flora", "pedido_especial")

func _on_solved(order_id: String, _reward: int) -> void:
	if order_id != "pedido_especial":
		return
	if not GameManager.is_challenge_completed(challenge_id):
		GameManager.complete_challenge(challenge_id)
		print("¡Pedido especial completado! Firma obtenida (%s)." % challenge_id)

func _on_closed() -> void:
	if not GameManager.is_challenge_completed(challenge_id):
		_used = false
