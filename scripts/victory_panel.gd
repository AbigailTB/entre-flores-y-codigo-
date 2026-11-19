extends CanvasLayer

@onready var title_label: Label = $Panel/VBox/Title
@onready var subtitle_label: Label = $Panel/VBox/Subtitle
@onready var menu_button: Button = $Panel/VBox/MenuBtn

var _final_step := 0

func _ready() -> void:
	add_to_group("modal_panel")
	layer = 97
	hide()
	menu_button.pressed.connect(_on_menu_pressed)

func mostrar(subtitulo: String = "Entre flores y código, lo lograste.", titulo: String = "🎉 ¡NIVEL COMPLETADO! 🎉") -> void:
	_final_step = 0
	title_label.text = titulo
	subtitle_label.text = subtitulo
	menu_button.text = "🏠 Volver al menú"
	show()

func mostrar_final() -> void:
	_final_step = 1
	title_label.text = "🎓 ¡Cuatrimestre completado! 🎓"
	subtitle_label.text = "Cumpliste tus metas: estudiaste, trabajaste y conseguiste todas tus firmas."
	menu_button.text = "Continuar ▶"
	AudioManager.play_named("firma")
	show()

func _on_menu_pressed() -> void:
	AudioManager.play_named("click")
	if _final_step == 1:
		_final_step = 2
		title_label.text = "🏆 ¡Has conseguido tu título universitario! 🏆"
		subtitle_label.text = "Entre flores y código, lo lograste."
		menu_button.text = "🏠 Volver al menú"
		return
	hide()
	HUD.hide()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
