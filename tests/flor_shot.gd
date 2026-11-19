extends Node
var _r := false
func _ready() -> void:
	if not _r:
		var n := Node.new(); n.set_script(get_script()); n.set("_r", true)
		get_tree().root.call_deferred("add_child", n); return
	var out: String = OS.get_cmdline_user_args()[0]
	var bk := FileAccess.get_file_as_string("user://progreso.json")
	GameManager.character = "aby"; HUD.show()
	get_tree().change_scene_to_file("res://scenes/floreria/Floreria.tscn")
	await _f(20)
	var p := get_tree().get_first_node_in_group("player")
	for spot in [Vector2(768, 700), Vector2(400, 620), Vector2(1150, 620)]:
		p.global_position = spot
		await _f(20)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join("flor_%d.png" % spot.x))
	print("FLOR ok")
	get_tree().change_scene_to_file("res://tests/blank.tscn")
	await _f(10)
	var fa := FileAccess.open("user://progreso.json", FileAccess.WRITE); fa.store_string(bk); fa.close()
	await _f(10)
	get_tree().quit()
func _f(n: int) -> void:
	for i in n: await get_tree().process_frame
