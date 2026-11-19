extends Node
## Juega la carrera completa: reta a cada maestro en orden y verifica candados, corazones y premios.

var _r := false
var out := ""

func _ready() -> void:
	if not _r:
		var n := Node.new(); n.set_script(get_script()); n.set("_r", true)
		get_tree().root.call_deferred("add_child", n); return
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else ""
	var backup := {}
	for f in ["user://progreso.json", "user://progreso.bak"]:
		if FileAccess.file_exists(f):
			backup[f] = FileAccess.get_file_as_string(f)
	GameManager.reset_progress()
	GameManager.character = "aby"
	GameManager.skill_id = "segunda"
	HUD.show()
	var fails := 0
	# 1) candados al inicio
	var expect := {"hermes": true, "heidy": false, "luis": false, "efren": false}
	for t in expect:
		if Career.is_teacher_unlocked(t) != expect[t]:
			print("CAREER FAIL candado inicial ", t); fails += 1
	# 2) reprobar a propósito con Hermes (daño 1, 5 corazones -> 5 errores; solo hay 4 preguntas => no reprueba)
	#    y con Luis más adelante. Aquí probamos con 4 errores: debe terminar sin aprobar.
	var r := await _run("metodologia_apa", "Teacher", false)
	print("CAREER hermes todo mal -> aprobado=", GameManager.is_teacher_defeated("hermes"), " ", r)
	if GameManager.is_teacher_defeated("hermes"):
		print("CAREER FAIL hermes no debió aprobar"); fails += 1
	# 3) aprobar en orden
	var order := [["metodologia_apa", "hermes"], ["documentacion", "juvencio"], ["metodologias_agiles", "gladis"],
		["matematicas", "heidy"], ["proyectos", "bety"], ["richi", "richi"],
		["seguridad", "ana"], ["redes", "jose"], ["web_pwa", "carlos"],
		["calculo", "yuls"], ["prog_movil", "gadiel"], ["programacion", "luis"]]
	for i in order.size():
		var room: String = order[i][0]
		var tid: String = order[i][1]
		if tid == "luis":
			# reprobar primero: daño 3, dos errores = 5-6 < 0
			var rr := await _run(room, "Teacher", false)
			print("CAREER luis reprobado -> ", rr, " aprobado=", GameManager.is_teacher_defeated("luis"))
			if GameManager.is_teacher_defeated("luis"):
				fails += 1
		var res := await _run(room, "Teacher", true, i == 9)
		var ok := GameManager.is_teacher_defeated(tid)
		print("CAREER ", tid, " aprobado=", ok, " xp=", GameManager.xp, " $", GameManager.money, " ", res)
		if not ok: fails += 1
	if not Career.is_teacher_unlocked("efren"):
		print("CAREER FAIL efren no se desbloqueó"); fails += 1
	var fr := await _run("", "Efren", true)
	print("CAREER efren aprobado=", GameManager.is_teacher_defeated("efren"), " terminada=", Career.career_finished(), " ", fr)
	print("CAREER rango=", Career.rank_name(), " xp=", GameManager.xp, " insignias=", GameManager.badges.size(), " ropa=", GameManager.unlocked_outfits)
	# captura del panel de avance
	get_tree().change_scene_to_file("res://scenes/campus/Campus.tscn")
	await _frames(30)
	await _shot("campus_avance")
	PauseMenu._pause()
	PauseMenu._open_progress()
	await _frames(5)
	await _shot("mi_avance")
	PauseMenu._resume()
	print("CAREER RESULT fallas=", fails)
	get_tree().change_scene_to_file("res://tests/blank.tscn")
	for k in 2:
		for f in backup:
			var fa := FileAccess.open(f, FileAccess.WRITE); fa.store_string(backup[f]); fa.close()
		await _frames(20)
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	if out == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))

## Entra al salón (o a la escuela si room == ""), habla con el maestro y responde.
func _run(room: String, node_name: String, answer_right: bool, shoot := false) -> String:
	var path := "res://scenes/escuela/Escuela.tscn" if room == "" else "res://scenes/campus/Aula_%s.tscn" % room
	get_tree().change_scene_to_file(path)
	await _frames(10)
	var t := get_tree().current_scene.get_node(node_name)
	var panel := get_tree().current_scene.get_node("UI/QuestionPanel")
	t.start_challenge()
	var asked := 0
	var guard := 0
	while guard < 200:
		guard += 1
		await _frames(2)
		if DialogueBox.visible:
			DialogueBox._on_next_pressed()
			continue
		if panel.visible:
			if shoot and asked == 1 and not answer_right == false:
				await _shot("reto_corazones")
			var qc: int = panel._current_question.respuesta_correcta
			var pick: int = qc if answer_right else (qc + 1) % panel.options_box.get_child_count()
			panel._on_option_pressed(pick, panel.options_box.get_child(pick))
			if not panel._answered:
				# segunda oportunidad de Aby: volver a fallar
				var pick2: int = (qc + 2) % panel.options_box.get_child_count()
				panel._on_option_pressed(pick2, panel.options_box.get_child(pick2))
			panel._on_continue_pressed()
			asked += 1
			continue
		if t._stage == 0:
			break
	return "preguntas=%d corazones=%d" % [asked, t._hearts]
