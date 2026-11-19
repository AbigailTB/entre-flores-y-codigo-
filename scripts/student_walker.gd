extends Node2D
## Alumno que camina por los pasillos del salón.
## Ligero a propósito: no usa física (no choca), sigue un grafo de puntos de paso
## y deja de procesarse cuando sale de la pantalla (VisibleOnScreenEnabler2D).

@export var npc_name: String = "Alumno"
@export var speed: float = 60.0
@export var waypoints: PackedVector2Array = PackedVector2Array()
## Pares de índices conectados: [a0, b0, a1, b1, ...]
@export var edges: PackedInt32Array = PackedInt32Array()
@export var lines: Array[String] = []

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var talk_area: Area2D = get_node_or_null("TalkArea")

var _adj: Dictionary = {}
var _current := 0
var _target := 0
var _wait := 0.0
var _talk_cooldown := 0.0

func _ready() -> void:
	for i in range(0, edges.size() - 1, 2):
		var a := edges[i]
		var b := edges[i + 1]
		_adj.get_or_add(a, []).append(b)
		_adj.get_or_add(b, []).append(a)
	if waypoints.is_empty():
		set_process(false)
		return
	_current = randi() % waypoints.size()
	position = waypoints[_current]
	_pick_next()
	_wait = randf_range(0.0, 2.5)
	if talk_area:
		talk_area.body_entered.connect(_on_body_entered)
	# Ritmo de pasos acorde a la velocidad (evita que parezca que se deslizan)
	anim.speed_scale = clampf(speed / 105.0, 0.55, 1.1)

func _pick_next() -> void:
	var options: Array = _adj.get(_current, [])
	_target = options[randi() % options.size()] if not options.is_empty() else _current

func _process(delta: float) -> void:
	_talk_cooldown = maxf(0.0, _talk_cooldown - delta)
	if _wait > 0.0:
		_wait -= delta
		_idle()
		return
	var goal: Vector2 = waypoints[_target]
	var to := goal - position
	var dist := to.length()
	if dist < 4.0:
		_current = _target
		_pick_next()
		_wait = randf_range(0.6, 3.0)
		return
	var v := to / dist * speed
	position += v * delta
	if absf(v.x) > absf(v.y):
		anim.flip_h = v.x < 0
		anim.play("walk_side")
	elif v.y < 0:
		anim.play("walk_up")
	else:
		anim.play("walk_down")

func _idle() -> void:
	var a := anim.animation
	if a == "walk_up":
		anim.play("idle_up")
	elif a == "walk_side":
		anim.play("idle_side")
	elif a == "walk_down":
		anim.play("idle_down")

func _on_body_entered(body: Node2D) -> void:
	if lines.is_empty() or _talk_cooldown > 0.0 or not body.is_in_group("player"):
		return
	_talk_cooldown = 12.0
	_wait = 2.5
	DialogueBox.show_dialogue(npc_name, [lines[randi() % lines.size()]])
