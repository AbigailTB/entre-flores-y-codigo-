extends Node

signal money_changed(new_amount: int)
signal challenge_completed(challenge_id: String)
signal xp_changed(new_xp: int)
signal career_changed

const SAVE_PATH := "user://progreso.json"
const SAVE_TMP := "user://progreso.tmp"
const SAVE_BAK := "user://progreso.bak"
const SAVE_VERSION := 4
const TOTAL_FIRMAS := 4
const DEFAULT_SCENE := "res://scenes/main/Main.tscn"

var money: int = 0
var completed_challenges: Array[String] = []
var unlocked_outfits: Array[String] = ["uniforme"]
var current_outfit: String = "uniforme"
var last_scene: String = DEFAULT_SCENE
## Personaje elegido al inicio: "aby" o "josh". Vacío = aún no elegido.
var character: String = ""
## Variante de habilidad elegida para el personaje (ver Skills.SKILLS).
var skill_id: String = ""
## Carrera: experiencia, maestros aprobados e insignias ganadas.
var xp: int = 0
var defeated_teachers: Array[String] = []
var badges: Array[String] = []

func _ready() -> void:
	load_progress()

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)
	save_progress()

## "xp" se muestra en el juego como AURA.
func add_xp(amount: int) -> void:
	xp = max(0, xp + amount)
	xp_changed.emit(xp)
	save_progress()

func is_teacher_defeated(teacher_id: String) -> bool:
	return teacher_id in defeated_teachers

func mark_teacher_defeated(teacher_id: String) -> void:
	if not defeated_teachers.has(teacher_id):
		defeated_teachers.append(teacher_id)
	career_changed.emit()
	save_progress()

func add_badge(badge_id: String) -> bool:
	if badges.has(badge_id):
		return false
	badges.append(badge_id)
	career_changed.emit()
	save_progress()
	return true

func spend_money(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	save_progress()
	return true

func unlock_outfit(outfit_id: String) -> void:
	if not unlocked_outfits.has(outfit_id):
		unlocked_outfits.append(outfit_id)
	save_progress()

func set_current_outfit(outfit_id: String) -> void:
	current_outfit = outfit_id
	save_progress()

func set_last_scene(scene_path: String) -> void:
	if scene_path == "" or scene_path == last_scene:
		return
	last_scene = scene_path
	save_progress()

func complete_challenge(challenge_id: String) -> void:
	if challenge_id in completed_challenges:
		return
	completed_challenges.append(challenge_id)
	challenge_completed.emit(challenge_id)
	save_progress()

func is_challenge_completed(challenge_id: String) -> bool:
	return challenge_id in completed_challenges

func get_firmas_count() -> int:
	return completed_challenges.size()

func has_progress() -> bool:
	return character != "" and (money > 0 or xp > 0 or defeated_teachers.size() > 0 or completed_challenges.size() > 0 or unlocked_outfits.size() > 1 or last_scene != DEFAULT_SCENE)

func has_character() -> bool:
	return character != ""

func set_character(char_id: String, skill: String) -> void:
	character = char_id
	skill_id = skill
	save_progress()

func set_skill(skill: String) -> void:
	skill_id = skill
	save_progress()

func player_name() -> String:
	return "Josmar" if character == "josh" else "Aby"

func companion_name() -> String:
	return "Aby" if character == "josh" else "Josmar"

func get_resume_scene() -> String:
	if ResourceLoader.exists(last_scene):
		return last_scene
	return DEFAULT_SCENE

func reset_progress() -> void:
	money = 0
	completed_challenges.clear()
	unlocked_outfits = ["uniforme"]
	current_outfit = "uniforme"
	last_scene = DEFAULT_SCENE
	character = ""
	skill_id = ""
	xp = 0
	defeated_teachers.clear()
	badges.clear()
	money_changed.emit(money)
	xp_changed.emit(xp)
	career_changed.emit()
	save_progress()

func save_progress() -> void:
	var data := {
		"version": SAVE_VERSION,
		"money": money,
		"completed_challenges": completed_challenges,
		"unlocked_outfits": unlocked_outfits,
		"current_outfit": current_outfit,
		"last_scene": last_scene,
		"character": character,
		"skill_id": skill_id,
		"xp": xp,
		"defeated_teachers": defeated_teachers,
		"badges": badges,
	}
	var file := FileAccess.open(SAVE_TMP, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(SAVE_BAK))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_TMP), ProjectSettings.globalize_path(SAVE_PATH))

func _read_save(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	return parsed

func load_progress() -> void:
	var parsed = _read_save(SAVE_PATH)
	if parsed == null:
		parsed = _read_save(SAVE_BAK)
	if parsed == null:
		return
	money = int(parsed.get("money", 0))
	completed_challenges.clear()
	for c in parsed.get("completed_challenges", []):
		completed_challenges.append(str(c))
	unlocked_outfits.clear()
	for o in parsed.get("unlocked_outfits", ["uniforme"]):
		unlocked_outfits.append(str(o))
	if not unlocked_outfits.has("uniforme"):
		unlocked_outfits.append("uniforme")
	current_outfit = str(parsed.get("current_outfit", "uniforme"))
	if not unlocked_outfits.has(current_outfit):
		current_outfit = "uniforme"
	last_scene = str(parsed.get("last_scene", DEFAULT_SCENE))
	# Partidas viejas (antes de elegir personaje) siguen como Aby.
	var default_char := "aby" if int(parsed.get("version", 1)) < 3 else ""
	character = str(parsed.get("character", default_char))
	skill_id = str(parsed.get("skill_id", ""))
	xp = int(parsed.get("xp", 0))
	defeated_teachers.clear()
	for t in parsed.get("defeated_teachers", []):
		defeated_teachers.append(str(t))
	badges.clear()
	for b in parsed.get("badges", []):
		badges.append(str(b))
