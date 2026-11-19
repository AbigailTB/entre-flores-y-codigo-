extends Area2D

@export var bouquet_panel_path: NodePath

var _bouquet_panel: Node
var _used := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_bouquet_panel = get_node(bouquet_panel_path)
	_bouquet_panel.closed.connect(_on_panel_closed)

func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player"):
		return
	_used = true
	var pedido: Dictionary = FlowerCatalog.random_order()
	_bouquet_panel.abrir_pedido(pedido["reqs"], pedido["recompensa"])

func _on_panel_closed() -> void:
	_used = false
