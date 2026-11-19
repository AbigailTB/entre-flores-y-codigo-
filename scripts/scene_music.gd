extends Node

@export var track: String = ""

func _ready() -> void:
	AudioManager.play_track(track)
	var scene := get_parent()
	if scene:
		GameManager.set_last_scene(scene.scene_file_path)
