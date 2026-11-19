extends Node
## Prueba de humo: carga cada escena, simula unos cuadros y guarda una captura.
## Uso: Godot --path . res://tests/smoke.tscn -- <carpeta_salida> <personaje>

var scenes := [
	"res://scenes/character_select/CharacterSelect.tscn",
	"res://scenes/main/Main.tscn",
	"res://scenes/campus/Campus.tscn",
	"res://scenes/escuela/Escuela.tscn",
	"res://scenes/floreria/Floreria.tscn",
	"res://scenes/campus/Aula_programacion.tscn",
	"res://scenes/campus/Aula_metodologia_apa.tscn",
	"res://scenes/campus/Aula_prog_movil.tscn",
	"res://scenes/campus/Aula_calculo.tscn",
	"res://scenes/campus/Aula_matematicas.tscn",
	"res://scenes/campus/Aula_documentacion.tscn",
	"res://scenes/campus/Aula_metodologias_agiles.tscn",
	"res://scenes/campus/Aula_seguridad.tscn",
	"res://scenes/campus/Aula_proyectos.tscn",
	"res://scenes/campus/Aula_web_pwa.tscn",
	"res://scenes/campus/Aula_redes.tscn",
	"res://scenes/campus/Aula_richi.tscn",
]

var _is_runner := false

func _ready() -> void:
	if not _is_runner:
		# La escena actual se libera al cambiar de escena: el trabajo lo hace una copia colgada de root.
		var runner := Node.new()
		runner.set_script(get_script())
		runner.set("_is_runner", true)
		get_tree().root.call_deferred("add_child", runner)
		return
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://smoke"
	var who: String = args[1] if args.size() > 1 else "aby"
	DirAccess.make_dir_recursive_absolute(out)
	# Respaldar el guardado real del jugador para restaurarlo al final.
	var backup := {}
	for f in ["user://progreso.json", "user://progreso.bak"]:
		if FileAccess.file_exists(f):
			backup[f] = FileAccess.get_file_as_string(f)
	var saved_char := GameManager.character
	var saved_skill := GameManager.skill_id
	GameManager.character = who
	GameManager.skill_id = Skills.skills_for(who)[0]["id"]
	HUD.show()
	await get_tree().process_frame
	for path in scenes:
		var err := get_tree().change_scene_to_file(path)
		if err != OK:
			print("SMOKE FAIL load ", path, " err=", err)
			continue
		await get_tree().process_frame
		var p0 := get_tree().get_first_node_in_group("player")
		if p0 and path.ends_with("Campus.tscn"):
			p0.global_position = Vector2(1152, 720)
		for i in 40:
			await get_tree().process_frame
		var guard := 0
		while get_tree().current_scene == null and guard < 300:
			await get_tree().process_frame
			guard += 1
		var scene := get_tree().current_scene
		var player := get_tree().get_first_node_in_group("player")
		var info := ""
		if player:
			info = " anim_frames=%s" % player.get_node("AnimatedSprite2D").sprite_frames.resource_path
			if path.contains("Aula_") or path.contains("Escuela"):
				player.global_position = Vector2(768, 470)
		# medir FPS ya cargado (3 s)
		var t0 := Time.get_ticks_msec()
		var frames := 0
		while Time.get_ticks_msec() - t0 < 3000:
			await get_tree().process_frame
			frames += 1
		var fps := frames / 3.0
		print("SMOKE OK ", path, " actual=", scene.scene_file_path, " nodes=", scene.get_child_count(), info, " fps_real=%.1f" % fps)
		await _shot(out, path.get_file().get_basename() + "_" + who)
		if path.ends_with("Campus.tscn") and player:
			for spot in [Vector2(1152, 720), Vector2(1152, 1000)]:
				player.global_position = spot
				for i in 30:
					await get_tree().process_frame
				await _shot(out, "Campus_%d_%d_%s" % [spot.x, spot.y, who])
		if path.ends_with("Aula_calculo.tscn") or path.ends_with("Aula_richi.tscn"):
			await _test_teacher(out, who, path.get_file().get_basename())
	# No tocar la partida real del usuario
	GameManager.character = saved_char
	GameManager.skill_id = saved_skill
	# Restaurar dos veces: alguna escena puede guardar justo al salir.
	get_tree().change_scene_to_file("res://tests/blank.tscn")
	for k in 2:
		for f in backup:
			var fa := FileAccess.open(f, FileAccess.WRITE)
			fa.store_string(backup[f])
			fa.close()
		await _wait_frames(20)
	get_tree().quit()

func _wait_frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(out: String, name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))

func _test_teacher(out: String, who: String, base: String) -> void:
	var teacher := get_tree().current_scene.get_node_or_null("Teacher")
	var player := get_tree().get_first_node_in_group("player")
	if teacher == null or player == null:
		print("SMOKE FAIL no teacher")
		return
	teacher._on_body_entered(player)
	await get_tree().process_frame
	var guard := 0
	while DialogueBox.visible and guard < 10:
		DialogueBox._on_next_pressed()
		await get_tree().process_frame
		guard += 1
	await get_tree().process_frame
	var panel := get_tree().current_scene.get_node("UI/QuestionPanel")
	print("SMOKE TEACHER panel_visible=", panel.visible, " header=", panel.header_label.text)
	await _shot(out, base + "_pregunta_" + who)
	if panel.skill_button.visible and not panel.skill_button.disabled:
		panel._on_skill_pressed()
		await get_tree().process_frame
		print("SMOKE SKILL feedback=", panel.feedback_label.text, " usos=", Skills.uses_left())
		await _shot(out, base + "_skill_" + who)
	var correct: int = panel._current_question.respuesta_correcta
	var money_before := GameManager.money
	panel._on_option_pressed(correct, panel.options_box.get_child(correct))
	panel._on_continue_pressed()
	await get_tree().process_frame
	print("SMOKE ANSWER money +", GameManager.money - money_before)
	while DialogueBox.visible:
		DialogueBox._on_next_pressed()
		await get_tree().process_frame
