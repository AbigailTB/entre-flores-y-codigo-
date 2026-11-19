extends CharacterBody2D

@export var npc_name: String = "NPC"
@export var lines: Array[String] = []
@export var portrait: Texture2D
@export var voice: String = ""
@export var bounds: Rect2 = Rect2(120, 260, 1300, 650)
@export var speed: float = 65.0
@export var wait_min: float = 1.2
@export var wait_max: float = 3.0
@export var hover: bool = false
@export var hover_amplitude: float = 5.0
@export var hover_speed: float = 2.4

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var talk_area: Area2D = $TalkArea

enum Direction { DOWN, UP, SIDE }
var _direction: Direction = Direction.DOWN
var _target: Vector2
var _wait_timer := 0.0
var _talking := false
var _last_dist := INF
var _stuck_timer := 0.0
var _hover_base_y := 0.0
var _hover_t := 0.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	_target = global_position
	_hover_base_y = animated_sprite.position.y
	talk_area.body_entered.connect(_on_player_entered)
	DialogueBox.dialogue_finished.connect(_on_dialogue_finished)
	_pick_new_target()

func _physics_process(delta: float) -> void:
	if hover:
		_hover_t += delta
		animated_sprite.position.y = _hover_base_y + sin(_hover_t * hover_speed) * hover_amplitude

	if _talking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if _wait_timer > 0.0:
		_wait_timer -= delta
		velocity = Vector2.ZERO
		_play_idle()
		move_and_slide()
		return

	var to_target: Vector2 = _target - global_position
	var dist := to_target.length()
	if dist < 8.0:
		_wait_timer = randf_range(wait_min, wait_max)
		_pick_new_target()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if dist < _last_dist - 2.0:
		_last_dist = dist
		_stuck_timer = 0.0
	else:
		_stuck_timer += delta
		if _stuck_timer > 1.0:
			_pick_new_target()
			_stuck_timer = 0.0
			_last_dist = INF
			velocity = Vector2.ZERO
			move_and_slide()
			return

	velocity = to_target.normalized() * speed
	move_and_slide()
	_update_animation(velocity)

func _pick_new_target() -> void:
	_target = Vector2(
		randf_range(bounds.position.x, bounds.end.x),
		randf_range(bounds.position.y, bounds.end.y)
	)
	_last_dist = INF
	_stuck_timer = 0.0

func _update_animation(v: Vector2) -> void:
	if v.length() < 5.0:
		_play_idle()
		return
	if abs(v.x) > abs(v.y):
		_direction = Direction.SIDE
		animated_sprite.flip_h = v.x < 0
		animated_sprite.play("walk_side")
	elif v.y < 0:
		_direction = Direction.UP
		animated_sprite.play("walk_up")
	else:
		_direction = Direction.DOWN
		animated_sprite.play("walk_down")

func _play_idle() -> void:
	match _direction:
		Direction.UP:
			animated_sprite.play("idle_up")
		Direction.SIDE:
			animated_sprite.play("idle_side")
		_:
			animated_sprite.play("idle_down")

func _on_player_entered(body: Node2D) -> void:
	if _talking or not body.is_in_group("player"):
		return
	_talking = true
	velocity = Vector2.ZERO
	_direction = Direction.DOWN
	animated_sprite.flip_h = false
	_play_idle()
	DialogueBox.show_dialogue(npc_name, lines, portrait, voice, animated_sprite)

func _on_dialogue_finished() -> void:
	_talking = false
