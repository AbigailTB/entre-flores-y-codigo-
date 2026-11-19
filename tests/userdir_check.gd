extends SceneTree
func _init() -> void:
	print("USERDIR ", OS.get_user_data_dir(), " existe_save=", FileAccess.file_exists("user://progreso.json"))
	quit()
