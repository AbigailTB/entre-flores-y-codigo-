extends Control
## Personalización al iniciar partida: elegir a Aby o a Josmar y la variante de su habilidad.

const INTRO_SCENE := "res://scenes/intro/Intro.tscn"

var _char_id := "aby"
var _skill_id := ""
var _cards := {}
var _skill_box: VBoxContainer
var _skill_buttons: Array = []
var _start_btn: Button
var _info_label: Label
var _anim_t := 0.0
var _previews := {}

func _ready() -> void:
	HUD.hide()
	AudioManager.play_track("menu")
	_build()
	_select_character("aby")

func _style(bg: Color, border: Color, radius := 18, width := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(width)
	s.border_color = border
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func _label(text: String, size: int, color := Color(1, 1, 1)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/backgrounds/inicio_minimal_v2b.png")
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var title := UiStyle.heavy_label("ELIGE TU PERSONAJE", 64, UiStyle.ROSE, UiStyle.LEAF, 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	var sub := _label("Cada personaje tiene su propia habilidad. Escoge la que más te guste: podrás cambiarla después en el menú de pausa (Esc).", 16, Color(0.88, 0.88, 0.95))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(sub)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 22)
	root.add_child(body)

	# Tarjetas de personaje
	for id in ["aby", "josh"]:
		var data: Dictionary = Skills.CHARACTERS[id]
		var card := Button.new()
		card.custom_minimum_size = Vector2(250, 0)
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.toggle_mode = true
		card.focus_mode = Control.FOCUS_NONE
		card.pressed.connect(_select_character.bind(id))
		var inner := VBoxContainer.new()
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner.offset_left = 12
		inner.offset_right = -12
		inner.offset_top = 12
		inner.offset_bottom = -12
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_theme_constant_override("separation", 6)
		var pic := TextureRect.new()
		pic.texture = load(data["preview"])
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pic.pivot_offset = Vector2(110, 300)
		_previews[id] = pic
		var name_l := UiStyle.heavy_label(data["nombre"], 44, data["color"], UiStyle.INK, 12)
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var full_l := _label(data["titulo"], 14, Color(0.8, 0.8, 0.9))
		full_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		full_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(pic)
		inner.add_child(name_l)
		card.add_child(inner)
		body.add_child(card)
		_cards[id] = card

	# Panel derecho: descripción + habilidades
	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_stylebox_override("panel", _style(Color(0.04, 0.06, 0.1, 0.92), UiStyle.NEON, 16))
	body.add_child(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 10)
	right.add_child(rv)
	_info_label = _label("", 17, Color(0.92, 0.92, 0.98))
	rv.add_child(_info_label)
	rv.add_child(UiStyle.heavy_label("HABILIDAD", 30, UiStyle.YELLOW, UiStyle.INK, 8))
	_skill_box = VBoxContainer.new()
	_skill_box.add_theme_constant_override("separation", 8)
	_skill_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(_skill_box)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 12)
	var back := Button.new()
	back.text = "Volver"
	UiStyle.set_button_icon(back, "arrow-left", UiStyle.CYAN, 22)
	back.custom_minimum_size = Vector2(150, 50)
	back.pressed.connect(_on_back)
	_start_btn = Button.new()
	_start_btn.text = "COMENZAR"
	UiStyle.set_button_icon(_start_btn, "play", UiStyle.INK, 26)
	_start_btn.custom_minimum_size = Vector2(240, 56)
	_start_btn.add_theme_font_override("font", UiStyle.title_font())
	_start_btn.add_theme_font_size_override("font_size", 26)
	_start_btn.add_theme_stylebox_override("normal", _style(UiStyle.NEON, Color(1, 1, 1, 0.6), 10, 2))
	_start_btn.add_theme_stylebox_override("hover", _style(Color(0.6, 1, 0.75), Color(1, 1, 1, 0.9), 10, 2))
	_start_btn.add_theme_color_override("font_color", Color(0.06, 0.08, 0.12))
	_start_btn.add_theme_color_override("font_hover_color", Color(0.06, 0.08, 0.12))
	_start_btn.pressed.connect(_on_start)
	bottom.add_child(back)
	bottom.add_child(_start_btn)
	rv.add_child(bottom)

func _select_character(id: String) -> void:
	AudioManager.play_named("click")
	_char_id = id
	for k in _cards:
		var c: Button = _cards[k]
		var col: Color = Skills.CHARACTERS[k]["color"]
		var active: bool = k == id
		c.button_pressed = active
		var st := _style(Color(0.06, 0.1, 0.16, 0.95) if active else Color(0.03, 0.04, 0.08, 0.85), col if active else Color(1, 1, 1, 0.15), 20, 4 if active else 2)
		for s in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
			c.add_theme_stylebox_override(s, st)
		_previews[k].modulate = Color(1, 1, 1) if active else Color(0.55, 0.55, 0.65)
	var data: Dictionary = Skills.CHARACTERS[id]
	_info_label.text = data["descripcion"]
	_build_skills()

func _build_skills() -> void:
	for b in _skill_box.get_children():
		b.queue_free()
	_skill_buttons.clear()
	var group := ButtonGroup.new()
	var list: Array = Skills.skills_for(_char_id)
	_skill_id = list[0]["id"]
	for s in list:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(0, 70)
		b.text = "%s  (%s)\n%s" % [s["nombre"], s["tipo"], s["desc"]]
		UiStyle.set_button_icon(b, s.get("icon", "zap"), UiStyle.ROSE, 30)
		b.add_theme_font_size_override("font_size", 15)
		b.add_theme_stylebox_override("normal", _style(Color(0.06, 0.08, 0.13), Color(1, 1, 1, 0.15), 10, 2))
		b.add_theme_stylebox_override("hover", _style(Color(0.09, 0.13, 0.2), UiStyle.CYAN, 10, 2))
		b.add_theme_stylebox_override("pressed", _style(Color(0.06, 0.2, 0.13), UiStyle.NEON, 10, 3))
		b.add_theme_stylebox_override("hover_pressed", _style(Color(0.06, 0.2, 0.13), UiStyle.NEON, 10, 3))
		b.pressed.connect(func(): _skill_id = s["id"]; AudioManager.play_named("click"))
		_skill_box.add_child(b)
		_skill_buttons.append(b)
	_skill_buttons[0].button_pressed = true

func _process(delta: float) -> void:
	# pequeña animación de "respirar" del personaje seleccionado
	_anim_t += delta
	for k in _previews:
		var p: TextureRect = _previews[k]
		var amp := 0.025 if k == _char_id else 0.0
		p.scale = Vector2(1.0, 1.0 + sin(_anim_t * 3.0) * amp)

func _on_back() -> void:
	AudioManager.play_named("click")
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")

func _on_start() -> void:
	AudioManager.play_named("correcto")
	GameManager.reset_progress()
	GameManager.set_character(_char_id, _skill_id)
	Skills.reset_uses()
	get_tree().change_scene_to_file(INTRO_SCENE)
