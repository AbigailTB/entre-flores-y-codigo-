extends Node
## Recorre las puertas como lo haría el jugador y verifica destino y que no rebote.

var _is_runner := false
var out := ""

func _ready() -> void:
	if not _is_runner:
		var r := Node.new()
		r.set_script(get_script())
		r.set("_is_runner", true)
		get_tree().root.call_deferred("add_child", r)
		return
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else ""
	var backup := {}
	for f in ["user://progreso.json", "user://progreso.bak"]:
		if FileAccess.file_exists(f):
			backup[f] = FileAccess.get_file_as_string(f)
	GameManager.character = "aby"
	# abrir todos los edificios (la prueba revisa puertas, no candados)
	for t in Career.TEACHERS:
		if not GameManager.defeated_teachers.has(t):
			GameManager.defeated_teachers.append(t)
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
	await _wait(1.0)
	await _shot("ruta_main")
	var plan := [["DoorUTHH", "Campus.tscn"], ["DoorDocencia", "Escuela.tscn"], ["DoorSalida", "Campus.tscn"]]
	for room in ["programacion", "metodologia_apa", "prog_movil", "calculo", "matematicas", "documentacion",
			"metodologias_agiles", "seguridad", "proyectos", "web_pwa", "redes", "richi"]:
		plan.append(["DoorAula_" + room, "Aula_%s.tscn" % room])
		plan.append(["DoorSalida", "Campus.tscn"])
	plan.append(["DoorToMain", "Main.tscn"])
	plan.append(["DoorFloreria", "Floreria.tscn"])
	plan.append(["DoorSalida", "Main.tscn"])
	var ok := 0
	for step in plan:
		var door := get_tree().current_scene.find_child(step[0], true, false)
		if door == null:
			print("ROUTE FAIL no existe ", step[0], " en ", get_tree().current_scene.scene_file_path)
			continue
		door._on_body_entered(get_tree().get_first_node_in_group("player"))
		await _wait(1.6)
		var guard := 0
		while get_tree().current_scene == null and guard < 300:
			await get_tree().process_frame
			guard += 1
		var now: String = get_tree().current_scene.scene_file_path
		if now.ends_with(step[1]):
			ok += 1
			var p := get_tree().get_first_node_in_group("player")
			print("ROUTE OK ", step[0], " -> ", now.get_file(), " en ", p.global_position)
			if now.ends_with("Campus.tscn") and step[0] == "DoorUTHH":
				await _shot("ruta_campus_entrada")
			if now.ends_with("Campus.tscn") and step[0] == "DoorSalida" and ok == 3:
				await _shot("ruta_campus_docencia")
		else:
			print("ROUTE FAIL ", step[0], " esperaba ", step[1], " y está en ", now)
	print("ROUTE RESULT ", ok, "/", plan.size())
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

func _wait(sec: float) -> void:
	var t := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < sec * 1000:
		await get_tree().process_frame

func _shot(name: String) -> void:
	if out == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
