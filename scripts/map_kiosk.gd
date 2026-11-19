extends Area2D
## Kiosco con el croquis del campus. Se abre al acercarse y se cierra con la ✕, con Esc
## o al alejarse. Después de cerrarlo no se vuelve a abrir hasta que te alejes y regreses.

@onready var overlay: CanvasLayer = $Overlay

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	overlay.visible = false
	overlay.layer = 96          # por encima del HUD
	var root := Control.new()
	root.name = "Root"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiUtil.add_close_button(root, close)
	var hint := Label.new()
	hint.text = "Pulsa Esc o la ✕ para cerrar el croquis"
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.14))
	hint.add_theme_constant_override("outline_size", 6)
	hint.position = Vector2(40, 690)
	root.add_child(hint)

func _unhandled_input(event: InputEvent) -> void:
	if overlay.visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func close() -> void:
	AudioManager.play_named("click")
	overlay.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		overlay.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		overlay.visible = false
