extends Node
## Estilo visual global del juego (oscuro tipo terminal + neón) y efectos de UI
## como los avisos "+100 AURA" / "-25 AURA".

## Nombre del juego: cámbialo aquí y se actualiza en el menú.
const GAME_TITLE := "Entre Flores y Código"
const GAME_SUBTITLE := "La carrera de TI y la Florería Bautista · UTHH"

const BG := Color(0.043, 0.059, 0.09)
const PANEL := Color(0.07, 0.09, 0.14, 0.96)
const PANEL_2 := Color(0.1, 0.13, 0.2, 1)
const NEON := Color(0.24, 1.0, 0.54)
const CYAN := Color(0.16, 0.83, 1.0)
const YELLOW := Color(1.0, 0.82, 0.25)
const RED := Color(1.0, 0.3, 0.37)
const ROSE := Color(1.0, 0.42, 0.62)
const LEAF := Color(0.08, 0.25, 0.12)
const TEXT := Color(0.91, 0.94, 1.0)
const MUTED := Color(0.54, 0.63, 0.75)
const INK := Color(0.03, 0.04, 0.06)

var _popup_layer: CanvasLayer

func _ready() -> void:
	get_tree().root.theme = build_theme()
	_popup_layer = CanvasLayer.new()
	_popup_layer.layer = 99
	add_child(_popup_layer)

func box(bg: Color, border: Color, radius := 14, width := 2, margin := 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(width)
	s.border_color = border
	s.set_content_margin_all(margin)
	return s

func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 18
	# Botones: oscuros con borde neón, al pasar el mouse se iluminan
	t.set_stylebox("normal", "Button", box(PANEL_2, Color(CYAN, 0.55), 12, 2))
	t.set_stylebox("hover", "Button", box(Color(0.13, 0.2, 0.3), CYAN, 12, 3))
	t.set_stylebox("pressed", "Button", box(Color(0.08, 0.25, 0.18), NEON, 12, 3))
	t.set_stylebox("hover_pressed", "Button", box(Color(0.08, 0.25, 0.18), NEON, 12, 3))
	t.set_stylebox("disabled", "Button", box(Color(0.08, 0.09, 0.12), Color(1, 1, 1, 0.08), 12, 2))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color(1, 1, 1))
	t.set_color("font_pressed_color", "Button", NEON)
	t.set_color("font_disabled_color", "Button", Color(TEXT, 0.55))
	t.set_stylebox("panel", "Panel", box(PANEL, ROSE, 18, 3))
	t.set_stylebox("panel", "PanelContainer", box(PANEL, NEON, 18, 3))
	t.set_color("font_color", "Label", TEXT)
	return t

func title_font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Impact", "Arial Black", "Segoe UI Black", "Verdana"])
	f.font_weight = 900
	return f

## Ícono de la librería Lucide (assets/ui/icons/<nombre>.svg).
func icon(name: String) -> Texture2D:
	var path := "res://assets/ui/icons/%s.svg" % name
	return load(path) if ResourceLoader.exists(path) else null

## Pone un ícono de Lucide a un botón, del mismo color que su texto.
func set_button_icon(b: Button, name: String, color: Color, size := 28) -> void:
	b.icon = icon(name)
	b.expand_icon = false
	b.add_theme_constant_override("icon_max_width", size)
	b.add_theme_constant_override("h_separation", 12)
	for k in ["icon_normal_color", "icon_focus_color"]:
		b.add_theme_color_override(k, color)
	for k in ["icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color"]:
		b.add_theme_color_override(k, Color(1, 1, 1))

func mono_font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Consolas", "Courier New", "Lucida Console"])
	f.font_weight = 800
	return f

func heavy_label(text: String, size: int, color: Color, outline: Color = INK, outline_size := 14) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", title_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", outline)
	l.add_theme_constant_override("outline_size", outline_size)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 6)
	return l

## Aviso grande tipo sticker: "+100 AURA" (amarillo) o "-25 AURA" (rojo).
func aura_popup(amount: int, extra := "") -> void:
	var positive := amount >= 0
	var box_v := VBoxContainer.new()
	box_v.alignment = BoxContainer.ALIGNMENT_CENTER
	box_v.add_theme_constant_override("separation", -14)
	var num := heavy_label(("+%d" % amount) if positive else str(amount), 72, Color(1, 1, 1) if positive else Color(0.2, 0.05, 0.05), INK if positive else Color(1, 1, 1), 16)
	var word := heavy_label("AURA", 64, YELLOW if positive else RED, INK, 16)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box_v.add_child(num)
	box_v.add_child(word)
	if extra != "":
		var e := heavy_label(extra, 26, TEXT, INK, 8)
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box_v.add_child(e)
	_popup_layer.add_child(box_v)
	box_v.size = Vector2(520, 220)
	var vp := get_viewport().get_visible_rect().size
	box_v.position = Vector2(vp.x * (0.78 if positive else 0.22) - 260, vp.y * 0.30)
	box_v.pivot_offset = box_v.size / 2
	box_v.scale = Vector2(0.3, 0.3)
	box_v.rotation = deg_to_rad(-6 if positive else 6)
	var tw := create_tween()
	tw.tween_property(box_v, "scale", Vector2(1.1, 1.1), 0.14).set_trans(Tween.TRANS_BACK)
	tw.tween_property(box_v, "scale", Vector2.ONE, 0.08)
	tw.tween_interval(0.7)
	tw.parallel().tween_property(box_v, "position:y", box_v.position.y - 40, 0.9)
	tw.tween_property(box_v, "modulate:a", 0.0, 0.3)
	tw.tween_callback(box_v.queue_free)

## Ícono grande que aparece y desaparece (trofeo, bomba...).
func icon_popup(texture_path: String, text: String, color: Color) -> void:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var tr := TextureRect.new()
	tr.texture = load(texture_path)
	tr.custom_minimum_size = Vector2(156, 144)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	v.add_child(tr)
	var l := heavy_label(text, 54, color, INK, 16)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	_popup_layer.add_child(v)
	v.size = Vector2(700, 260)
	var vp := get_viewport().get_visible_rect().size
	v.position = Vector2(vp.x / 2 - 350, vp.y * 0.22)
	v.pivot_offset = v.size / 2
	v.scale = Vector2(0.2, 0.2)
	var tw := create_tween()
	tw.tween_property(v, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(1.3)
	tw.tween_property(v, "modulate:a", 0.0, 0.35)
	tw.tween_callback(v.queue_free)
