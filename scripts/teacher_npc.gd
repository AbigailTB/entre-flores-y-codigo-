extends Area2D
## Maestro como reto de la carrera. Al hablarle inicia una ronda de preguntas de su
## materia con 5 corazones; cada error quita corazones según la dificultad de la materia.
## Si los corazones llegan a 0 se reprueba y hay que reintentar. Si el maestro aún no
## está desbloqueado (cuatrimestre anterior sin aprobar) solo platica.

@export var teacher_id: String = ""
@export var npc_name: String = "Profesor"
@export var materia: String = ""
@export var lines: Array[String] = []
@export var portrait: Texture2D
@export var voice: String = ""
@export var question_panel_path: NodePath

@onready var sprite: Sprite2D = get_node_or_null("Sprite")

enum Stage { IDLE, INTRO, ASKING, OUTRO }
var _stage := Stage.IDLE
var _question_panel: Control
var _base_scale := Vector2.ONE
var _t := 0.0
var _talks := 0

# estado del reto
var _hearts := 0
var _index := 0
var _total := 0
var _damage := 1
var _correct := 0
var _used_ids: Array = []
var _scene_track := ""

# --- hoja de sprites del profe (opcional): assets/sprites/teachers/<id>/ ---
const PACK_DIR := "res://assets/sprites/teachers/%s/"
const PACK_HEIGHT := 140.0       # alto en pantalla, parecido al de los alumnos
var _anim: AnimatedSprite2D
var _home := Vector2.ZERO
var _walk_to := 0.0
var _wait := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_question_panel = get_node_or_null(question_panel_path)
	if _question_panel:
		_question_panel.question_finished.connect(_on_question_finished)
		_question_panel.question_cancelled.connect(_on_question_cancelled)
		_question_panel.answered.connect(_on_answered)
	DialogueBox.dialogue_finished.connect(_on_dialogue_finished)
	if sprite:
		_base_scale = sprite.scale
	_t = randf() * 10.0
	_home = position
	_setup_pack()

func _pack_tex(name: String) -> Texture2D:
	var path := (PACK_DIR % teacher_id) + name + ".png"
	return load(path) if ResourceLoader.exists(path) else null

## Si el profe tiene su carpeta de sprites, camina frente al pizarrón y cambia de cara.
func _setup_pack() -> void:
	if teacher_id == "" or _pack_tex("walk_1") == null:
		return
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim_def in [["walk", "walk_", 9.0], ["idle", "idle_side_", 2.5], ["back", "back_", 6.0]]:
		frames.add_animation(anim_def[0])
		frames.set_animation_speed(anim_def[0], anim_def[2])
		frames.set_animation_loop(anim_def[0], true)
		var k := 1
		while true:
			var tex := _pack_tex(anim_def[1] + str(k))
			if tex == null:
				break
			frames.add_frame(anim_def[0], tex)
			k += 1
	if frames.get_frame_count("idle") == 0:
		frames.add_frame("idle", _pack_tex("walk_1"))
	_anim = AnimatedSprite2D.new()
	_anim.sprite_frames = frames
	var h := float(frames.get_frame_texture("walk", 0).get_height())
	_anim.scale = Vector2.ONE * (PACK_HEIGHT / h)
	_anim.offset = Vector2(0, -h / 2.0)
	add_child(_anim)
	_anim.play("idle")
	if sprite:
		sprite.hide()
	_wait = randf_range(0.5, 2.0)
	var face := _pack_tex("face_normal")
	if face:
		portrait = face

## Cara para el diálogo según el momento (si el profe tiene hoja de expresiones).
func _face(mood: String) -> Texture2D:
	if _anim:
		var t := _pack_tex("face_" + mood)
		if t:
			return t
	return portrait

func _wander(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		if _anim.animation != "idle":
			_anim.play("idle")
		if _wait <= 0.0:
			_walk_to = _home.x + randf_range(-60.0, 170.0)
		return
	var dx := _walk_to - position.x
	if absf(dx) < 3.0:
		_wait = randf_range(1.5, 4.0)
		return
	_anim.flip_h = dx < 0
	if _anim.animation != "walk":
		_anim.play("walk")
	position.x += signf(dx) * minf(absf(dx), 40.0 * delta)

func _face_player() -> void:
	if _anim == null:
		return
	var p := get_tree().get_first_node_in_group("player") as Node2D
	_anim.play("idle")
	if p:
		_anim.flip_h = p.global_position.x < global_position.x

func _process(delta: float) -> void:
	if _anim:
		if _stage == Stage.IDLE:
			_wander(delta)
		return
	if sprite and _stage == Stage.IDLE:
		_t += delta
		sprite.scale = _base_scale * Vector2(1.0, 1.0 + sin(_t * 2.2) * 0.012)

func _info() -> Dictionary:
	return Career.teacher(teacher_id)

func _say(text_lines: Array, next_stage: Stage, mood := "normal") -> void:
	_stage = next_stage
	if sprite:
		sprite.scale = _base_scale
	_face_player()
	DialogueBox.show_dialogue(npc_name, text_lines, _face(mood), voice, _anim if _anim else sprite)

func _on_body_entered(body: Node2D) -> void:
	if _stage != Stage.IDLE or not body.is_in_group("player"):
		return
	start_challenge()

## Inicia la plática / el reto (también lo usan las pruebas automáticas).
func start_challenge() -> void:
	var info := _info()
	var intro: Array = lines.duplicate() if _talks == 0 else ["¡Otra vez por aquí, {p}!"]
	_talks += 1
	if info.is_empty():
		_say(intro, Stage.OUTRO)
		return
	var c := Career.cuatri_of(teacher_id)
	if not Career.is_teacher_unlocked(teacher_id):
		var prev: Dictionary = Career.CUATRIS[max(0, Career.CUATRIS.find(c) - 1)]
		intro.append("Mi reto es del %s. Primero aprueba el %s y luego vienes conmigo." % [c["nombre"], prev["nombre"]])
		_say(intro, Stage.OUTRO, "serious")
		return
	_hearts = Career.START_HEARTS
	_damage = int(info["dano"])
	_total = int(info["preguntas"])
	_index = 0
	_correct = 0
	_used_ids.clear()
	if GameManager.is_teacher_defeated(teacher_id):
		intro.append("Ya me aprobaste, pero un repaso nunca sobra. ¡Va de nuevo!")
	intro.append("RETO · %s · %s. Tienes %d ❤ y son %d preguntas." % [c.get("nombre", ""), c.get("dificultad", ""), _hearts, _total])
	_scene_track = AudioManager._current_track
	intro.append("Cada error te quita %d ❤. Para aprobar necesitas calificación mínima de 7 (%d de %d bien) y no quedarte sin corazones. ¡Demuestra tus conocimientos!" % [_damage, _min_correct(), _total])
	_say(intro, Stage.INTRO, "glasses")

func _on_dialogue_finished() -> void:
	match _stage:
		Stage.INTRO:
			_stage = Stage.ASKING
			AudioManager.play_track("reto")
			HUD.show_hearts(_hearts, Career.START_HEARTS)
			_ask_next()
		Stage.OUTRO:
			_stage = Stage.IDLE

## Aciertos necesarios para sacar al menos 7 de calificación.
func _min_correct() -> int:
	return int(ceil(_total * 0.7))

func _grade() -> float:
	return snappedf(10.0 * _correct / max(_total, 1), 0.1)

func _hearts_text() -> String:
	return "Pregunta %d de %d   ·   Si te equivocas pierdes %d corazón%s   ·   Para aprobar: %d bien" % [_index + 1, _total, _damage, "" if _damage == 1 else "es", _min_correct()]

func _pick_question():
	var info := _info()
	for attempt in 8:
		var q
		if info["materia"] == "*":
			q = QuestionBank.get_random_question()     # examen final: de todas las materias
		else:
			q = QuestionBank.get_random_question_by_subject(info["materia"])
		if q and not _used_ids.has(q.get_instance_id()):
			_used_ids.append(q.get_instance_id())
			return q
	return QuestionBank.get_random_question()

func _ask_next() -> void:
	var q = _pick_question()
	if q == null or _question_panel == null:
		_stage = Stage.IDLE
		return
	_question_panel.set_status(_hearts_text())
	_question_panel.penalty_hint = "pierdes %d corazón%s" % [_damage, "" if _damage == 1 else "es"]
	_question_panel.show_question(q, npc_name)
	if _anim:
		_question_panel.set_face(_face("thinking"))

func _on_answered(was_correct: bool) -> void:
	if _stage == Stage.ASKING and _anim:
		_question_panel.set_face(_face("laugh" if was_correct else "angry"))

func _on_question_finished(was_correct: bool, _points: int) -> void:
	if _stage != Stage.ASKING:
		return
	if was_correct:
		_correct += 1
		var plus := Career.aura_per_correct(teacher_id)
		GameManager.add_xp(plus)
		UiStyle.aura_popup(plus)
		AudioManager.play_named("aura")
	else:
		_hearts -= _damage
		var minus := Career.aura_per_wrong(teacher_id)
		GameManager.add_xp(minus)
		UiStyle.aura_popup(minus, "-%d ❤" % _damage)
		AudioManager.play_named("golpe")
	HUD.show_hearts(max(_hearts, 0), Career.START_HEARTS)
	_index += 1
	if _hearts <= 0:
		_end_challenge(false)
		_say([
			"Te quedaste sin corazones... 💔 Reprobaste este intento.",
			"No pasa nada, {p}: repasa en el pupitre de práctica y vuelve a intentarlo.",
		], Stage.OUTRO, "mad")
		return
	if _index >= _total and _correct < _min_correct():
		_end_challenge(false)
		_say([
			"Sacaste %s de calificación (%d de %d). Necesitabas al menos 7... 📉" % [str(_grade()), _correct, _total],
			"Repasa en el pupitre de práctica y vuelve a intentarlo, {p}. ¡Tú puedes!",
		], Stage.OUTRO, "angry")
		return
	if _index >= _total:
		_end_challenge(true)
		var reward_lines: Array = ["¡Muy bien, {p}! Sacaste %s de calificación (%d de %d) y te quedaron %d ❤." % [str(_grade()), _correct, _total, _hearts]]
		reward_lines.append_array(Career.on_teacher_beaten(teacher_id, _hearts))
		HUD.refresh()
		_say(reward_lines, Stage.OUTRO, "happy")
		return
	_ask_next()

## Termina el reto: quita los corazones, regresa la música del salón y celebra o no.
func _end_challenge(won: bool) -> void:
	HUD.hide_hearts()
	if _scene_track != "":
		AudioManager.play_track(_scene_track)
	if won:
		AudioManager.play_named("victoria")
		UiStyle.icon_popup("res://assets/ui/pixel/trofeo.png", "¡APROBADO!", UiStyle.YELLOW)
	else:
		AudioManager.play_named("explosion")
		AudioManager.play_named("derrota")
		UiStyle.icon_popup("res://assets/ui/pixel/bomba.png", "REPROBADO", UiStyle.RED)

func _on_question_cancelled() -> void:
	if _stage != Stage.ASKING:
		return
	HUD.hide_hearts()
	if _scene_track != "":
		AudioManager.play_track(_scene_track)
	_say(["Reto cancelado. No pasa nada, {p}: vuelve cuando estés list%s." % ("o" if GameManager.character == "josh" else "a")], Stage.OUTRO, "wink")
