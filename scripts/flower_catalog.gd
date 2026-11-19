extends Node

const FLOWERS := [
	{"id": "rosa_roja", "nombre": "Rosa roja", "icon": "res://assets/items/rosa_roja.png", "pixel": "res://assets/sprites/flowers/rosa_roja.png"},
	{"id": "rosa_blanca", "nombre": "Rosa blanca", "icon": "res://assets/sprites/flowers/rosa_blanca.png", "pixel": "res://assets/sprites/flowers/rosa_blanca.png"},
	{"id": "margarita", "nombre": "Margarita", "icon": "res://assets/items/margarita.png", "pixel": "res://assets/sprites/flowers/margarita.png"},
	{"id": "girasol", "nombre": "Girasol", "icon": "res://assets/items/girasol.png", "pixel": "res://assets/sprites/flowers/girasol.png"},
	{"id": "tulipan", "nombre": "Tulipán", "icon": "res://assets/sprites/flowers/tulipan.png", "pixel": "res://assets/sprites/flowers/tulipan.png"},
	{"id": "lirio", "nombre": "Lirio", "icon": "res://assets/sprites/flowers/lirio.png", "pixel": "res://assets/sprites/flowers/lirio.png"},
	{"id": "clavel", "nombre": "Clavel", "icon": "res://assets/sprites/flowers/clavel.png", "pixel": "res://assets/sprites/flowers/clavel.png"},
	{"id": "hortensia", "nombre": "Hortensia", "icon": "res://assets/sprites/flowers/hortensia.png", "pixel": "res://assets/sprites/flowers/hortensia.png"},
	{"id": "violeta", "nombre": "Violeta", "icon": "res://assets/sprites/flowers/violeta.png", "pixel": "res://assets/sprites/flowers/violeta.png"},
	{"id": "lavanda", "nombre": "Lavanda", "icon": "res://assets/sprites/flowers/lavanda.png", "pixel": "res://assets/sprites/flowers/lavanda.png"},
	{"id": "orquidea", "nombre": "Orquídea", "icon": "res://assets/sprites/flowers/orquidea.png", "pixel": "res://assets/sprites/flowers/orquidea.png"},
	{"id": "gerbera", "nombre": "Gerbera", "icon": "res://assets/sprites/flowers/gerbera.png", "pixel": "res://assets/sprites/flowers/gerbera.png"},
]

func get_flower(flower_id: String) -> Dictionary:
	for f in FLOWERS:
		if f["id"] == flower_id:
			return f
	return {}

func random_order() -> Dictionary:
	var pool: Array = FLOWERS.duplicate()
	pool.shuffle()
	var kinds := randi_range(2, 3)
	var reqs: Array = []
	var total := 0
	for i in kinds:
		var qty := randi_range(1, 3)
		total += qty
		reqs.append({"id": pool[i]["id"], "nombre": pool[i]["nombre"], "requerido": qty, "actual": 0})
	return {"reqs": reqs, "recompensa": 12 * total + 10}
