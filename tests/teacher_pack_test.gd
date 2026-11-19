extends Node
var _r := false
func _ready() -> void:
	if not _r:
		var n := Node.new(); n.set_script(get_script()); n.set("_r", true)
		get_tree().root.call_deferred("add_child", n); return
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var room: String = args[1] if args.size() > 1 else "documentacion"
	var backup := {}
	for f in ["user://progreso.json", "user://progreso.bak"]:
		if FileAccess.file_exists(f): backup[f] = FileAccess.get_file_as_string(f)
	GameManager.character = "aby"; GameManager.skill_id = "segunda"
	for tid in Career.TEACHERS:
		if not GameManager.defeated_teachers.has(tid):
			GameManager.defeated_teachers.append(tid)
	HUD.show()
	get_tree().change_scene_to_file("res://scenes/campus/Aula_%s.tscn" % room)
	await _frames(10)
	var t := get_tree().current_scene.get_node("Teacher")
	var p := get_tree().get_first_node_in_group("player")
	p.global_position = Vector2(700, 560)
	var x0: float = t.position.x
	await _secs(4.0)
	print("PACK anim=", t._anim != null, " se_movio=", absf(t.position.x - x0) > 5, " anim_actual=", t._anim.animation if t._anim else "")
	await _shot(out, room + "_camina")
	t.start_challenge()
	await _frames(3)
	await _shot(out, room + "_dialogo")
	while DialogueBox.visible:
		DialogueBox._on_next_pressed(); await _frames(2)
	await _frames(4)
	var panel := get_tree().current_scene.get_node("UI/QuestionPanel")
	print("PACK cara_pregunta=", panel.face_rect.visible)
	await _shot(out, room + "_pregunta")
	if panel._current_question != null:
		var qc: int = panel._current_question.respuesta_correcta
		panel._on_option_pressed(qc, panel.options_box.get_child(qc))
	await _frames(6)
	await _shot(out, room + "_bien")
	panel.cancel()
	await _frames(3)
	while DialogueBox.visible:
		DialogueBox._on_next_pressed(); await _frames(2)
	print("PACK RESULT ok")
	get_tree().change_scene_to_file("res://tests/blank.tscn")
	for k in 2:
		for f in backup:
			var fa := FileAccess.open(f, FileAccess.WRITE); fa.store_string(backup[f]); fa.close()
		await _frames(20)
	get_tree().quit()
func _frames(n: int) -> void:
	for i in n: await get_tree().process_frame
func _secs(s: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < s * 1000: await get_tree().process_frame
func _shot(out: String, name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
