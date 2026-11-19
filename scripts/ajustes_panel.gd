extends Control

signal closed

@onready var music_check: CheckButton = $Card/VBox/MusicRow/MusicCheck
@onready var music_slider: HSlider = $Card/VBox/MusicSlider
@onready var sfx_check: CheckButton = $Card/VBox/SfxRow/SfxCheck
@onready var sfx_slider: HSlider = $Card/VBox/SfxSlider
@onready var close_button: Button = $CloseBtn
@onready var reset_button: Button = $Card/VBox/ResetBtn
@onready var reset_msg: Label = $Card/VBox/ResetMsg

var _confirm_reset := false

func _ready() -> void:
	add_to_group("modal_panel")
	hide()
	close_button.pressed.connect(_on_close_pressed)
	close_button.text = ""
	UiStyle.set_button_icon(close_button, "x", Color(1, 1, 1), 24)
	reset_button.pressed.connect(_on_reset_pressed)
	music_check.toggled.connect(_on_music_toggled)
	sfx_check.toggled.connect(_on_sfx_toggled)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)

func abrir() -> void:
	_confirm_reset = false
	reset_button.text = "🗑 Borrar progreso"
	reset_msg.text = ""
	music_check.button_pressed = AudioManager.music_enabled
	sfx_check.button_pressed = AudioManager.sfx_enabled
	music_slider.value = AudioManager.music_volume
	sfx_slider.value = AudioManager.sfx_volume
	show()

func _on_music_toggled(pressed: bool) -> void:
	AudioManager.set_music_enabled(pressed)

func _on_sfx_toggled(pressed: bool) -> void:
	AudioManager.set_sfx_enabled(pressed)

func _on_music_volume_changed(value: float) -> void:
	AudioManager.set_music_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)

func _on_close_pressed() -> void:
	hide()
	closed.emit()

func _on_reset_pressed() -> void:
	if not _confirm_reset:
		_confirm_reset = true
		reset_button.text = "¿Seguro? Pulsa de nuevo para borrar todo"
		return
	GameManager.reset_progress()
	AudioManager.play_named("incorrecto")
	_confirm_reset = false
	reset_button.text = "🗑 Borrar progreso"
	reset_msg.text = "Progreso borrado. Empezarás desde cero."
