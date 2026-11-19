extends Area2D

@export var npc_name: String = "NPC"
@export var lines: Array[String] = []
@export var portrait: Texture2D
@export var voice: String = ""
@export var talk_texture: Texture2D
@export var bob_amplitude: float = 0.0
@export var bob_speed: float = 3.0

@onready var sprite: Sprite2D = get_node_or_null("Sprite")

var _used := false
var _base_y := 0.0
var _idle_texture: Texture2D
var _t := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if sprite:
		_base_y = sprite.position.y
		_idle_texture = sprite.texture
	DialogueBox.dialogue_finished.connect(_on_dialogue_finished)

func _process(delta: float) -> void:
	if sprite and bob_amplitude > 0.0:
		_t += delta
		sprite.position.y = _base_y + sin(_t * bob_speed) * bob_amplitude

func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player"):
		return
	_used = true
	if sprite and talk_texture:
		sprite.texture = talk_texture
	DialogueBox.show_dialogue(npc_name, lines, portrait, voice, sprite)

func _on_dialogue_finished() -> void:
	if sprite and talk_texture:
		sprite.texture = _idle_texture

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_used = false
