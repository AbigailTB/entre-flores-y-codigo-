extends Sprite2D

@export var challenge_id: String = ""

var _base_y := 0.0
var _t := 0.0

func _ready() -> void:
	_base_y = position.y
	if challenge_id != "":
		visible = not GameManager.is_challenge_completed(challenge_id)
		GameManager.challenge_completed.connect(_on_completed)

func _on_completed(id: String) -> void:
	if id == challenge_id:
		hide()

func _process(delta: float) -> void:
	_t += delta
	position.y = _base_y + sin(_t * 3.0) * 5.0
