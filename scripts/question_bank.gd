extends Node

const QUESTIONS_PATH := "res://data/questions"

var _pool: Array[Question] = []
var _by_subject: Dictionary = {}
## Mazos barajados: no se repite una pregunta hasta usar todas las de ese mazo.
var _decks: Dictionary = {}

func _ready() -> void:
	var dir := DirAccess.open(QUESTIONS_PATH)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		# En el juego exportado los .tres aparecen como .tres.remap
		var clean := file_name.trim_suffix(".remap")
		if clean.ends_with(".tres"):
			var q := load(QUESTIONS_PATH + "/" + clean) as Question
			if q:
				_pool.append(q)
				if not _by_subject.has(q.materia):
					_by_subject[q.materia] = []
				_by_subject[q.materia].append(q)
		file_name = dir.get_next()
	dir.list_dir_end()

func _draw(key: String, source: Array) -> Question:
	if source.is_empty():
		return null
	var deck: Array = _decks.get(key, [])
	if deck.is_empty():
		deck = source.duplicate()
		deck.shuffle()
	var q: Question = deck.pop_back()
	_decks[key] = deck
	return q

func get_random_question() -> Question:
	return _draw("*", _pool)

func get_random_question_by_subject(materia: String) -> Question:
	var subset: Array = _by_subject.get(materia, [])
	if subset.is_empty():
		return get_random_question()
	return _draw(materia, subset)

## tipo: "Pregunta" o "Acertijo". Si no hay de ese tipo, cae a cualquiera de la materia.
func get_by_subject_and_type(materia: String, tipo: String) -> Question:
	var subset: Array = []
	for q in _by_subject.get(materia, []):
		if q.tipo == tipo:
			subset.append(q)
	if subset.is_empty():
		return get_random_question_by_subject(materia)
	return _draw(materia + "|" + tipo, subset)

func count_for(materia: String) -> int:
	return _by_subject.get(materia, []).size()
