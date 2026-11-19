extends Node
## Personajes jugables y sus habilidades personalizables.
## Cada personaje tiene 3 variantes de habilidad; el jugador elige una al iniciar
## (y puede cambiarla después desde el menú de pausa).

signal uses_changed(left: int)

const CHARACTERS := {
	"aby": {
		"nombre": "Aby",
		"titulo": "Alondra Abigail",
		"descripcion": "Estudiante de Desarrollo de Software y florista de medio tiempo. Paciente, creativa y muy observadora.",
		"preview": "res://assets/sprites/player/walk_down_1.png",
		"portrait": "res://assets/portraits/face_happy.png",
		"color": Color(1, 0.35, 0.6),
	},
	"josh": {
		"nombre": "Josmar",
		"titulo": "Josmar Aldair",
		"descripcion": "Compañero de Aby en la UTHH. Rápido con el teclado, fan de depurar código y siempre con buenos consejos.",
		"preview": "res://assets/sprites/josh/uniforme/idle_down.png",
		"portrait": "res://assets/portraits/josmar_happy.png",
		"color": Color(0.16, 0.83, 1.0),
	},
}

## tipo: "activa" (botón en las preguntas, con usos por salón) o "pasiva" (siempre activa).
const SKILLS := {
	"aby": [
		{"id": "descarte", "nombre": "Descarte floral", "icon": "flower-2", "tipo": "activa", "usos": 2,
			"desc": "Quita 2 respuestas incorrectas de una pregunta. 2 usos en cada salón."},
		{"id": "segunda", "nombre": "Segunda oportunidad", "icon": "heart", "tipo": "pasiva", "usos": 1,
			"desc": "Si fallas una pregunta puedes volver a intentarla. 1 vez en cada salón."},
		{"id": "florista", "nombre": "Florista experta", "icon": "flower", "tipo": "pasiva", "usos": 0,
			"desc": "Ganas +50% de dinero en los ramos de la florería y en las respuestas correctas."},
	],
	"josh": [
		{"id": "debug", "nombre": "Modo debug", "icon": "code-xml", "tipo": "activa", "usos": 1,
			"desc": "Revela la respuesta correcta de una pregunta. 1 uso en cada salón."},
		{"id": "racha", "nombre": "Racha de código", "icon": "zap", "tipo": "pasiva", "usos": 0,
			"desc": "Cada respuesta correcta te da el doble de dinero."},
		{"id": "turbo", "nombre": "Paso veloz", "icon": "timer", "tipo": "pasiva", "usos": 0,
			"desc": "Caminas 35% más rápido por el campus, la escuela y la florería."},
	],
}

var _uses_left := 0
var _scene_key := ""

func character_data(char_id: String = "") -> Dictionary:
	if char_id == "":
		char_id = current_character()
	return CHARACTERS.get(char_id, CHARACTERS["aby"])

func current_character() -> String:
	return GameManager.character if GameManager.character in CHARACTERS else "aby"

func skills_for(char_id: String) -> Array:
	return SKILLS.get(char_id, SKILLS["aby"])

func current_skill() -> Dictionary:
	var list := skills_for(current_character())
	for s in list:
		if s["id"] == GameManager.skill_id:
			return s
	return list[0]

func has(skill_id: String) -> bool:
	return current_skill()["id"] == skill_id

## Se llama al entrar a cada escena jugable: recarga los usos por salón.
func on_scene_entered(scene_path: String) -> void:
	if scene_path == _scene_key:
		return
	_scene_key = scene_path
	_uses_left = int(current_skill().get("usos", 0))
	uses_changed.emit(_uses_left)

func uses_left() -> int:
	return _uses_left

func consume() -> bool:
	if _uses_left <= 0:
		return false
	_uses_left -= 1
	uses_changed.emit(_uses_left)
	return true

func reset_uses() -> void:
	_scene_key = ""

## Multiplicador de dinero para respuestas correctas.
func answer_money_multiplier() -> float:
	if has("racha"):
		return 2.0
	if has("florista"):
		return 1.5
	return 1.0

## Multiplicador de dinero para pedidos de la florería.
func floreria_multiplier() -> float:
	return 1.5 if has("florista") else 1.0

func speed_multiplier() -> float:
	return 1.35 if has("turbo") else 1.0
