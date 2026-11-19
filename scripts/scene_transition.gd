extends CanvasLayer

@onready var fade_rect: ColorRect = $FadeRect

var _pending_spawn: Vector2
var _has_pending_spawn := false

func go_to(scene_path: String, spawn_position: Vector2) -> void:
	_pending_spawn = spawn_position
	_has_pending_spawn = true

	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.25)
	await tween.finished

	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame

	_apply_pending_spawn()

	var tween_in := create_tween()
	tween_in.tween_property(fade_rect, "color:a", 0.0, 0.25)


func _apply_pending_spawn() -> void:
	if not _has_pending_spawn:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = _pending_spawn
	_has_pending_spawn = false
