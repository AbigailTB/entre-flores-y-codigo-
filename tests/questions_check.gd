extends SceneTree
func _init() -> void:
	var bad := 0
	var total := 0
	var d := DirAccess.open("res://data/questions")
	for f in d.get_files():
		if not f.ends_with(".tres"):
			continue
		total += 1
		var q = load("res://data/questions/" + f)
		if q == null or q.opciones.size() < 2 or q.respuesta_correcta >= q.opciones.size() or q.enunciado.length() < 8 or q.explicacion == "":
			bad += 1
			print("QBAD ", f)
	print("QCHECK total=", total, " malas=", bad)
	quit()
