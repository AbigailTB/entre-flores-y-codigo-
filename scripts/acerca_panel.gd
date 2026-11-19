extends Control

const CREDITOS := "Desarrollado por:\nAlondra Abigail Torres Badillo\nJosmar Aldair Bautista Saavedra"

@onready var credits_label: Label = $Card/VBox/Credits
@onready var close_button: Button = $CloseBtn

func _ready() -> void:
	add_to_group("modal_panel")
	hide()
	credits_label.text = CREDITOS
	close_button.pressed.connect(_on_close_pressed)
	close_button.text = ""
	UiStyle.set_button_icon(close_button, "x", Color(1, 1, 1), 24)

func abrir() -> void:
	show()

func _on_close_pressed() -> void:
	AudioManager.play_named("click")
	hide()
