extends Node
var _r := false
var out := ""
func _ready() -> void:
	if not _r:
		var n := Node.new(); n.set_script(get_script()); n.set("_r", true)
		get_tree().root.call_deferred("add_child", n); return
	out = OS.get_cmdline_user_args()[0]
	var backup := {}
	for f in ["user://progreso.json", "user://progreso.bak"]:
		if FileAccess.file_exists(f):
			backup[f] = FileAccess.get_file_as_string(f)
	var fails := 0
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
	await _frames(40); await _shot("ui_menu")
	get_tree().current_scene.get_node("AcercaDePanel").abrir()
	await _frames(5); await _shot("ui_acerca")
	get_tree().current_scene.get_node("AcercaDePanel").hide()
	get_tree().change_scene_to_file("res://scenes/character_select/CharacterSelect.tscn")
	await _frames(30); await _shot("ui_personaje")
	GameManager.character = "aby"; GameManager.skill_id = "descarte"
	HUD.show()
	# 1) reto con X a mitad
	get_tree().change_scene_to_file("res://scenes/campus/Aula_metodologia_apa.tscn")
	await _frames(10)
	var t := get_tree().current_scene.get_node("Teacher")
	var panel := get_tree().current_scene.get_node("UI/QuestionPanel")
	t.start_challenge()
	while DialogueBox.visible:
		DialogueBox._on_next_pressed(); await _frames(2)
	await _frames(3)
	await _shot("ui_pregunta_x")
	# responder mal una para ver corazones y -AURA
	var qc0: int = panel._current_question.respuesta_correcta
	var wrong: int = (qc0 + 1) % panel.options_box.get_child_count()
	panel._on_option_pressed(wrong, panel.options_box.get_child(wrong))
	panel._on_continue_pressed()
	await _frames(12)
	await _shot("ui_corazones")
	var cb := panel.get_node_or_null("Card/CloseBtn")
	print("UI close_btn=", cb != null, " visible=", panel.visible)
	cb.emit_signal("pressed")
	await _frames(3)
	print("UI tras X: panel=", panel.visible, " dialogo=", DialogueBox.visible, " stage=", t._stage)
	if panel.visible: fails += 1
	while DialogueBox.visible:
		DialogueBox._on_next_pressed(); await _frames(2)
	if t._stage != 0: fails += 1
	# 2) práctica con Esc
	var pr := get_tree().current_scene.get_node("Practica")
	pr._on_body_entered(get_tree().get_first_node_in_group("player"))
	await _frames(3)
	var ev := InputEventAction.new(); ev.action = "ui_cancel"; ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(4)
	print("UI practica tras Esc: panel=", panel.visible, " pausa=", PauseMenu.visible, " used=", pr._used)
	if panel.visible or PauseMenu.visible or pr._used: fails += 1
	# 3) panel de código en la escuela
	get_tree().change_scene_to_file("res://scenes/escuela/Escuela.tscn")
	await _frames(10)
	var cbp := get_tree().current_scene.get_node("UI/CodeBugPanel")
	cbp.mostrar_bug(CodeBugBank.get_random_bug())
	await _frames(3)
	cbp.get_node("Card/CloseBtn").emit_signal("pressed")
	await _frames(3)
	print("UI codigo tras X: visible=", cbp.visible)
	if cbp.visible: fails += 1
	# 4) croquis
	get_tree().change_scene_to_file("res://scenes/campus/Campus.tscn")
	await _frames(10)
	var k := get_tree().current_scene.get_node("MapKiosk")
	k._on_body_entered(get_tree().get_first_node_in_group("player"))
	await _frames(3); await _shot("ui_croquis")
	Input.parse_input_event(ev)
	await _frames(4)
	print("UI croquis tras Esc: visible=", k.overlay.visible, " pausa=", PauseMenu.visible)
	if k.overlay.visible or PauseMenu.visible: fails += 1
	k._on_body_entered(get_tree().get_first_node_in_group("player"))
	await _frames(2)
	var kb := k.overlay.get_node_or_null("Root/CloseBtn") as Button
	print("UI croquis boton=", kb != null, " rect=", kb.get_global_rect() if kb else Rect2())
	if kb == null: fails += 1
	else: kb.emit_signal("pressed")
	await _frames(2)
	print("UI croquis tras X: visible=", k.overlay.visible)
	if k.overlay.visible: fails += 1
	print("UI RESULT fallas=", fails)
	get_tree().change_scene_to_file("res://tests/blank.tscn")
	for i in 2:
		for f in backup:
			var fa := FileAccess.open(f, FileAccess.WRITE); fa.store_string(backup[f]); fa.close()
		await _frames(20)
	get_tree().quit()
func _frames(n: int) -> void:
	for i in n: await get_tree().process_frame
func _shot(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
