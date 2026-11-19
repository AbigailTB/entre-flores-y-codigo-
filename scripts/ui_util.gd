class_name UiUtil
extends RefCounted

## Botón ✕ rojo en la esquina superior derecha de un control.
static func add_close_button(parent: Control, callback: Callable) -> Button:
	var close := Button.new()
	close.name = "CloseBtn"
	close.text = ""
	close.icon = UiStyle.icon("x")
	close.expand_icon = false
	close.add_theme_constant_override("icon_max_width", 24)
	close.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close.tooltip_text = "Cerrar (Esc)"
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 26)
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.95, 0.35, 0.45)
	cs.set_corner_radius_all(22)
	var ch := cs.duplicate()
	ch.bg_color = Color(1, 0.5, 0.58)
	close.add_theme_stylebox_override("normal", cs)
	close.add_theme_stylebox_override("hover", ch)
	close.add_theme_stylebox_override("pressed", ch)
	close.add_theme_color_override("font_color", Color(1, 1, 1))
	parent.add_child(close)
	close.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close.offset_left = -58
	close.offset_right = -14
	close.offset_top = 14
	close.offset_bottom = 58
	close.pressed.connect(callback)
	return close
