extends Control

func _lines() -> Array:
	var skill: Dictionary = Skills.current_skill()
	if GameManager.character == "josh":
		return [
			"¡Qué onda! Soy Josmar, estudiante de Desarrollo de Software en la UTHH.",
			"Mi amiga Aby trabaja en la Florería Bautista y me invitó a echarle la mano mientras terminamos el cuatrimestre.",
			"La carrera de TI va por cuatrimestres: en cada uno hay que aprobar a 3 profes. Empiezo con 5 corazones por reto y cada error me quita según la materia.",
			"Al final, el profe Efrén nos aplica el examen final. ¡A juntar AURA, monedas y trofeos!",
			"Mi habilidad es %s. %s" % [skill["nombre"], skill["desc"]],
			"Aby anda en la escuela: si me atoro, ella siempre tiene un buen consejo. ¡Vamos!",
		]
	return [
		"Hola, soy Aby.",
		"En esta aventura vamos a aprender sobre Desarrollo de Software mientras trabajamos en la Florería Bautista.",
		"La carrera de TI va por cuatrimestres: en cada uno debo aprobar a 3 profes del campus. Tengo 5 corazones por reto y cada error me quita según la materia.",
		"Al final, el profe Efrén me aplica el examen final. ¡A juntar AURA, monedas y trofeos!",
		"Mi habilidad es %s. %s" % [skill["nombre"], skill["desc"]],
		"Mi compañero Josmar siempre me da buenos consejos: búscalo en la escuela. ¡Vamos a comenzar!",
	]

func _ready() -> void:
	AudioManager.play_track("menu")
	var portrait := get_node_or_null("AbyPortrait") as TextureRect
	if portrait:
		portrait.texture = load(Skills.character_data()["portrait"])
	DialogueBox.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
	DialogueBox.show_dialogue(GameManager.player_name(), _lines())

func _on_dialogue_finished() -> void:
	HUD.show()
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
