extends CharacterBody2D

@export var speed: float = 220.0
var world_bounds := Rect2(30, 30, 1476, 964)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

enum Direction { DOWN, UP, SIDE }
var last_direction: Direction = Direction.DOWN
var _step_timer := 0.0

var _base_speed := 220.0
var _modal_panels: Array = []
var _modal_refresh := 0.0

# --- sentado en un pupitre ---
var seated := false
var _sit_sprite: Sprite2D
var _hidden_chair: CanvasItem

func _ready() -> void:
	OutfitManager.apply_current(self)
	_prepare_idles()
	_base_speed = speed
	speed = _base_speed * Skills.speed_multiplier()
	var scene := get_tree().current_scene
	if scene:
		Skills.on_scene_entered(scene.scene_file_path)
	_refresh_modals()
	_fit_world_to_background()

## Ajusta límites de cámara y de movimiento al tamaño del fondo de la escena
## (el campus es más grande que los salones).
func _fit_world_to_background() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var bg := scene.get_node_or_null("Background") as Sprite2D
	if bg == null or bg.texture == null:
		return
	var size := bg.texture.get_size() * bg.scale
	var top_left := bg.global_position - size / 2.0 if bg.centered else bg.global_position
	var rect := Rect2(top_left, size)
	world_bounds = rect.grow(-30)
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.limit_left = int(rect.position.x)
		cam.limit_top = int(rect.position.y)
		cam.limit_right = int(rect.end.x)
		cam.limit_bottom = int(rect.end.y)

func _refresh_modals() -> void:
	_modal_panels = get_tree().get_nodes_in_group("modal_panel")

func _is_blocked() -> bool:
	# La lista de paneles se refresca cada medio segundo en vez de cada cuadro.
	for p in _modal_panels:
		if is_instance_valid(p) and p.visible:
			return true
	return false

func _physics_process(delta: float) -> void:
	_modal_refresh -= delta
	if _modal_refresh <= 0.0:
		_modal_refresh = 0.5
		_refresh_modals()
	if seated:
		velocity = Vector2.ZERO
		if not _is_blocked() and _input_vector() != Vector2.ZERO:
			stand_up()
		return
	if _is_blocked():
		velocity = Vector2.ZERO
		_step_timer = 0.0
		_play_idle()
		return
	var input_vector := _input_vector()

	velocity = input_vector * speed
	move_and_slide()
	global_position = global_position.clamp(world_bounds.position, world_bounds.end)

	# Si choca contra algo y no avanza, se queda en pose de pie en vez de "caminar en su lugar".
	if input_vector != Vector2.ZERO and get_real_velocity().length() < 8.0:
		_update_animation(input_vector)
		_play_idle()
	else:
		_update_animation(input_vector)

	if input_vector != Vector2.ZERO and get_real_velocity().length() > 20.0:
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = 0.34
			AudioManager.play_named("paso", -12.0)
	else:
		_step_timer = 0.0


func _update_animation(input_vector: Vector2) -> void:
	if input_vector == Vector2.ZERO:
		_play_idle()
		return

	if abs(input_vector.x) > abs(input_vector.y):
		last_direction = Direction.SIDE
		animated_sprite.flip_h = input_vector.x < 0
		animated_sprite.play("walk_side")
	elif input_vector.y < 0:
		last_direction = Direction.UP
		animated_sprite.play("walk_up")
	else:
		last_direction = Direction.DOWN
		animated_sprite.play("walk_down")


func _play_idle() -> void:
	var anim := "idle_down"
	match last_direction:
		Direction.UP:
			anim = "idle_up"
		Direction.SIDE:
			anim = "idle_side"
	if animated_sprite.animation != anim:
		animated_sprite.play(anim)
	animated_sprite.frame = 0

## Pose de pie al detenerse: de cada caminata se toma el cuadro con los pies más
## juntos (el más angosto) como "quieto", así no se queda a medio paso.
func _prepare_idles() -> void:
	var frames := animated_sprite.sprite_frames
	if frames == null or frames.has_meta("idles_ok"):
		return
	frames = frames.duplicate()
	for pair in [["walk_side", "idle_side"], ["walk_up", "idle_up"]]:
		if not frames.has_animation(pair[0]):
			continue
		var best: Texture2D = null
		var best_w := 1 << 30
		for i in frames.get_frame_count(pair[0]):
			var tex := frames.get_frame_texture(pair[0], i)
			var img := tex.get_image()
			if img == null:
				continue
			var used := img.get_used_rect()
			# solo la mitad inferior (piernas) decide qué tan abierto va el paso
			var legs := img.get_region(Rect2i(0, img.get_height() / 2, img.get_width(), img.get_height() / 2)).get_used_rect()
			if legs.size.x < best_w:
				best_w = legs.size.x
				best = tex
		if best:
			if not frames.has_animation(pair[1]):
				frames.add_animation(pair[1])
			frames.clear(pair[1])
			frames.add_frame(pair[1], best)
	frames.set_meta("idles_ok", true)
	var current := animated_sprite.animation
	animated_sprite.sprite_frames = frames
	animated_sprite.play(current if frames.has_animation(current) else "idle_down")


func _input_vector() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()

## Se sienta en la silla (de espaldas, viendo al pizarrón) en la posición dada.
func sit_at(seat_pos: Vector2) -> void:
	var char_id := "josh" if GameManager.character == "josh" else "aby"
	var path := "res://assets/sprites/player_sit/%s_%s.png" % [char_id, GameManager.current_outfit]
	if not ResourceLoader.exists(path):
		path = "res://assets/sprites/player_sit/%s_uniforme.png" % char_id
	if not ResourceLoader.exists(path):
		face_board()
		return
	if _sit_sprite == null:
		_sit_sprite = Sprite2D.new()
		_sit_sprite.name = "SitSprite"
		add_child(_sit_sprite)
	_sit_sprite.texture = load(path)
	_sit_sprite.scale = Vector2.ONE / scale        # el nodo del jugador está escalado
	_sit_sprite.offset = Vector2(0, -44)
	_sit_sprite.show()
	animated_sprite.hide()
	var sh := get_node_or_null("Shadow") as CanvasItem
	if sh:
		sh.hide()
	# ocultar la silla vacía que ya estaba ahí (la imagen sentado trae su propia silla)
	_hidden_chair = null
	var scene := get_tree().current_scene
	if scene:
		for n in scene.get_children():
			if n is Sprite2D and (n.name.begins_with("Silla") or n.name.begins_with("Chair")):
				if absf(n.global_position.x - seat_pos.x) < 30 and absf(n.global_position.y - seat_pos.y) < 50:
					_hidden_chair = n
					n.hide()
					break
	global_position = seat_pos
	last_direction = Direction.UP
	seated = true

func stand_up() -> void:
	if not seated:
		return
	seated = false
	if _sit_sprite:
		_sit_sprite.hide()
	animated_sprite.show()
	var sh := get_node_or_null("Shadow") as CanvasItem
	if sh:
		sh.show()
	if _hidden_chair and is_instance_valid(_hidden_chair):
		_hidden_chair.show()
	_hidden_chair = null
	global_position += Vector2(0, 40)       # se levanta hacia el pasillo
	_play_idle()

func face_board(step: Vector2 = Vector2(0, -55)) -> void:
	last_direction = Direction.UP
	animated_sprite.play("idle_up")
	var tween := create_tween()
	tween.tween_property(self, "global_position", global_position + step, 0.25)

func set_outfit(frames: SpriteFrames) -> void:
	var current_animation := animated_sprite.animation
	animated_sprite.sprite_frames = frames
	# Ajustar los pies al suelo segun el alto del sprite (Aby 348 px, Josh 315 px).
	var tex := frames.get_frame_texture("idle_down", 0) if frames.has_animation("idle_down") else null
	if tex:
		animated_sprite.offset = Vector2(0, -tex.get_height() / 2.0)
	if frames.has_animation(current_animation):
		animated_sprite.play(current_animation)
	else:
		animated_sprite.play("idle_down")
	_prepare_idles()
