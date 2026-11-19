extends Node

const BUGS_PATH := "res://data/code_bugs"

var _pool: Array[CodeBug] = []
var _last_index := -1

func _ready() -> void:
	var dir := DirAccess.open(BUGS_PATH)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var b := load(BUGS_PATH + "/" + file_name) as CodeBug
			if b:
				_pool.append(b)
		file_name = dir.get_next()
	dir.list_dir_end()

func get_random_bug() -> CodeBug:
	if _pool.is_empty():
		return null
	if _pool.size() == 1:
		return _pool[0]
	var index := randi() % _pool.size()
	while index == _last_index:
		index = randi() % _pool.size()
	_last_index = index
	return _pool[index]
