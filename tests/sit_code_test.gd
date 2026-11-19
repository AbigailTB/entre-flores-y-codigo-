extends Node
var _r := false
func _ready() -> void:
	if not _r:
		var n := Node.new(); n.set_script(get_script()); n.set("_r", true)
		get_tree().root.call_deferred("add_child", n); return
	var out: String = OS.get_cmdline_user_args()[0]
	var backup := {}
	for f in ["user://progreso.json", "user://progreso.bak"]:
		if FileAccess.file_exists(f): backup[f] = FileAccess.get_file_as_string(f)
	GameManager.character = "aby"; GameManager.skill_id = "descarte"
	HUD.show()
	get_tree().change_scene_to_file("res://scenes/campus/Aula_programacion.tscn")
	await _frames(10)
	var p := get_tree().get_first_node_in_group("player")
	var pr := get_tree().current_scene.get_node("Practica")
	pr._on_body_entered(p)
	await _frames(4)
	var panel := get_tree().current_scene.get_node("UI/QuestionPanel")
	print("SIT sentado=", p.seated, " pos=", p.global_position)
	# forzar una pregunta con código
	var qcode = null
	for q in QuestionBank._pool:
		if q.materia == "Programación" and q.codigo != "":
			qcode = q; break
	panel.show_question(qcode, "Práctica")
	await _frames(4)
	await _shot(out, "code_pregunta")
	var rc: int = qcode.respuesta_correcta
	var w: int = (rc + 1) % 4
	panel.penalty_hint = "pierdes 3 corazones"
	panel._on_option_pressed(w, panel.options_box.get_child(w))
	await _frames(4)
	await _shot(out, "code_error")
	panel._on_continue_pressed()
	await _frames(4)
	panel.hide()
	await _frames(4)
	await _shot(out, "sentado")
	Input.action_press("move_down")
	await _frames(6)
	Input.action_release("move_down")
	await _frames(4)
	print("SIT tras moverse sentado=", p.seated)
	# quieto: debe quedar en pose de pie (idle)
	Input.action_press("move_right")
	await _frames(20)
	Input.action_release("move_right")
	await _frames(6)
	print("SIT anim al detenerse=", p.animated_sprite.animation, " frame=", p.animated_sprite.frame)
	await _shot(out, "quieto")
	print("SIT RESULT ok")
	get_tree().change_scene_to_file("res://tests/blank.tscn")
	for k in 2:
		for f in backup:
			var fa := FileAccess.open(f, FileAccess.WRITE); fa.store_string(backup[f]); fa.close()
		await _frames(20)
	get_tree().quit()
func _frames(n: int) -> void:
	for i in n: await get_tree().process_frame
func _shot(out: String, name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
