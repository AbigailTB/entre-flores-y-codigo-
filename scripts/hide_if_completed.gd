extends CanvasItem

@export var challenge_id: String = ""

func _ready() -> void:
	visible = not GameManager.is_challenge_completed(challenge_id)
	GameManager.challenge_completed.connect(_on_completed)

func _on_completed(id: String) -> void:
	if id == challenge_id:
		hide()
