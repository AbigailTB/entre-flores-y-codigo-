extends Node

const OUTFITS := [
	{"id": "uniforme", "nombre": "Uniforme UTHH", "precio": 0, "frames": "res://data/outfits/uniforme.tres", "preview": "res://assets/sprites/player/walk_down_2.png"},
	{"id": "camisa_verde", "nombre": "Camisa verde", "precio": 100, "frames": "res://data/outfits/camisa_verde.tres", "preview": "res://assets/sprites/player_variants/camisa_verde/walk_down_2.png"},
	{"id": "camisa_roja", "nombre": "Camisa roja", "precio": 150, "frames": "res://data/outfits/camisa_roja.tres", "preview": "res://assets/sprites/player_variants/camisa_roja/walk_down_2.png"},
	{"id": "camisa_amarilla", "nombre": "Camisa amarilla", "precio": 150, "frames": "res://data/outfits/camisa_amarilla.tres", "preview": "res://assets/sprites/player_variants/camisa_amarilla/walk_down_2.png"},
	{"id": "camisa_morada", "nombre": "Camisa morada", "precio": 200, "frames": "res://data/outfits/camisa_morada.tres", "preview": "res://assets/sprites/player_variants/camisa_morada/walk_down_2.png"},
	{"id": "camisa_turquesa", "nombre": "Camisa turquesa", "precio": 200, "frames": "res://data/outfits/camisa_turquesa.tres", "preview": "res://assets/sprites/player_variants/camisa_turquesa/walk_down_2.png"},
]

## Rutas segun el personaje elegido (Josmar tiene sus propias versiones de cada camisa).
func frames_path(outfit_id: String, char_id: String = "") -> String:
	if char_id == "":
		char_id = GameManager.character
	if char_id == "josh":
		return "res://data/outfits/josh_%s.tres" % outfit_id
	return find_outfit(outfit_id).get("frames", "res://data/outfits/uniforme.tres")

func preview_path(outfit_id: String, char_id: String = "") -> String:
	if char_id == "":
		char_id = GameManager.character
	if char_id == "josh":
		return "res://assets/sprites/josh/%s/idle_down.png" % outfit_id
	return find_outfit(outfit_id).get("preview", "")

func find_outfit(outfit_id: String) -> Dictionary:
	for o in OUTFITS:
		if o["id"] == outfit_id:
			return o
	return {}

func is_unlocked(outfit_id: String) -> bool:
	return GameManager.unlocked_outfits.has(outfit_id)

func apply_current(player: Node) -> void:
	var data := find_outfit(GameManager.current_outfit)
	var outfit_id: String = GameManager.current_outfit if not data.is_empty() else "uniforme"
	if outfit_id == "uniforme" and GameManager.character != "josh":
		return
	player.set_outfit(load(frames_path(outfit_id)))

func equip(outfit_id: String) -> void:
	var data := find_outfit(outfit_id)
	if data.is_empty() or not is_unlocked(outfit_id):
		return
	GameManager.set_current_outfit(outfit_id)
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.set_outfit(load(frames_path(outfit_id)))

func buy(outfit_id: String) -> String:
	var data := find_outfit(outfit_id)
	if data.is_empty():
		return "error"
	if is_unlocked(outfit_id):
		return "ya_tienes"
	if not GameManager.spend_money(int(data["precio"])):
		return "sin_dinero"
	GameManager.unlock_outfit(outfit_id)
	equip(outfit_id)
	return "ok"
