extends Area2D

@export var target_scene: String = ""
@export var target_spawn: Vector2 = Vector2.ZERO
## Si tiene maestro, la puerta respeta el cuatrimestre: cerrada hasta desbloquearlo.
@export var teacher_id: String = ""

var _badge: Label
var _cooldown := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if teacher_id != "":
		_build_badge()
		GameManager.career_changed.connect(_refresh_badge)

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta

func _build_badge() -> void:
	_badge = Label.new()
	_badge.z_index = 30
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge.position = Vector2(-110, -64)
	_badge.size = Vector2(220, 30)
	_badge.add_theme_font_size_override("font_size", 16)
	_badge.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.14))
	_badge.add_theme_constant_override("outline_size", 6)
	add_child(_badge)
	_refresh_badge()

func _refresh_badge() -> void:
	if _badge == null:
		return
	var c := Career.cuatri_of(teacher_id)
	var n: String = c.get("nombre", "")
	if GameManager.is_teacher_defeated(teacher_id):
		_badge.text = "✔ Aprobado · " + n
		_badge.add_theme_color_override("font_color", Color(0.55, 1, 0.6))
	elif Career.is_teacher_unlocked(teacher_id):
		_badge.text = "▶ " + n
		_badge.add_theme_color_override("font_color", Color(1, 0.9, 0.45))
	else:
		_badge.text = "Bloqueado · " + n
		_badge.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))

func _on_body_entered(body: Node2D) -> void:
	if target_scene == "":
		return
	if not body.is_in_group("player"):
		return
	if teacher_id != "" and not Career.is_teacher_unlocked(teacher_id):
		if _cooldown <= 0.0:
			_cooldown = 2.0
			AudioManager.play_named("incorrecto")
			var c := Career.cuatri_of(teacher_id)
			var idx := Career.CUATRIS.find(c)
			var prev: Dictionary = Career.CUATRIS[max(0, idx - 1)]
			DialogueBox.show_dialogue("Edificio cerrado", [
				"Este edificio es del %s." % c.get("nombre", ""),
				"Primero aprueba a los maestros del %s. Revisa tu avance en el menú de pausa (Esc → Mi avance)." % prev.get("nombre", ""),
			])
		return
	AudioManager.play_named("puerta")
	get_node("/root/Transition").go_to(target_scene, target_spawn)
