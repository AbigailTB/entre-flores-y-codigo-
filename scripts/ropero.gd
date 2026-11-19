extends Area2D

@export var outfit_panel_path: NodePath

var _outfit_panel: Node
var _used := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_outfit_panel = get_node(outfit_panel_path)
	_outfit_panel.closed.connect(_on_closed)

func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player"):
		return
	_used = true
	_outfit_panel.abrir()

func _on_closed() -> void:
	_used = false
