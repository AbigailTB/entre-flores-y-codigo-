extends Control
## Menú principal: fondo tech pixel-art, título grande con efecto glitch y botones neón.

const FONDO := "res://assets/backgrounds/inicio_minimal_v2.png"

@onready var ajustes_panel: Control = $AjustesPanel
@onready var acerca_panel: Control = $AcercaDePanel
@onready var buttons: Array = [$Card/VBox/JugarBtn, $Card/VBox/AjustesBtn, $Card/VBox/AcercaDeBtn, $Card/VBox/SalirBtn]

var _title_box: Control
var _glitch_a: Label
var _glitch_b: Label
var _t := 0.0
var _glitch_timer := 2.0

## Compatibilidad: otras pantallas usan este título grande.
static func titulo_label(text: String, size: int, color: Color, outline: Color, outline_size := 16) -> Label:
	return UiStyle.heavy_label(text, size, color, outline, outline_size)

func _ready() -> void:
	HUD.hide()
	AudioManager.play_track("menu")
	_restyle()
	for b in buttons:
		b.mouse_entered.connect(_on_hover.bind(b, true))
		b.mouse_exited.connect(_on_hover.bind(b, false))
		b.pressed.connect(AudioManager.play_named.bind("click"))
	await get_tree().process_frame
	for b in buttons:
		b.pivot_offset = b.size / 2.0

func _btn_style(b: Button, accent: Color) -> void:
	var n := UiStyle.box(Color(0.05, 0.07, 0.11, 0.92), accent, 10, 3, 10)
	var h := UiStyle.box(Color(accent.r * 0.25, accent.g * 0.25, accent.b * 0.25, 0.95), accent, 10, 4, 10)
	n.shadow_color = Color(accent, 0.35)
	n.shadow_size = 8
	h.shadow_color = Color(accent, 0.6)
	h.shadow_size = 16
	for k in ["normal", "focus"]:
		b.add_theme_stylebox_override(k, n)
	for k in ["hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(k, h)
	b.add_theme_font_override("font", UiStyle.title_font())
	b.add_theme_font_size_override("font_size", 30)
	b.add_theme_color_override("font_color", accent)
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	b.custom_minimum_size = Vector2(0, 66)

func _restyle() -> void:
	var bg := get_node_or_null("Background") as TextureRect
	if bg:
		bg.texture = load(FONDO)
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var card := $Card as Panel
	card.add_theme_stylebox_override("panel", UiStyle.box(Color(0.03, 0.04, 0.08, 0.72), Color(UiStyle.NEON, 0.6), 16, 2))
	card.anchor_left = 1.0
	card.anchor_right = 1.0
	card.anchor_top = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -430
	card.offset_right = -60
	card.offset_top = -190
	card.offset_bottom = 230
	for n in ["Title", "Flowers", "Spacer"]:
		var node := card.get_node_or_null("VBox/" + n)
		if node:
			node.hide()
	_btn_style($Card/VBox/JugarBtn, UiStyle.NEON)
	_btn_style($Card/VBox/AjustesBtn, UiStyle.YELLOW)
	_btn_style($Card/VBox/AcercaDeBtn, UiStyle.ROSE)
	_btn_style($Card/VBox/SalirBtn, UiStyle.RED)
	$Card/VBox/JugarBtn.text = "JUGAR"
	$Card/VBox/AjustesBtn.text = "AJUSTES"
	$Card/VBox/AcercaDeBtn.text = "ACERCA DE"
	$Card/VBox/SalirBtn.text = "SALIR"
	UiStyle.set_button_icon($Card/VBox/JugarBtn, "play", UiStyle.NEON)
	UiStyle.set_button_icon($Card/VBox/AjustesBtn, "settings", UiStyle.YELLOW)
	UiStyle.set_button_icon($Card/VBox/AcercaDeBtn, "info", UiStyle.ROSE)
	UiStyle.set_button_icon($Card/VBox/SalirBtn, "power", UiStyle.RED)

	# Título mitad flores / mitad código. Va justo después del fondo para que
	# los paneles (Acerca de / Ajustes) queden encima.
	_title_box = Control.new()
	_title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_box.position = Vector2(60, 60)
	add_child(_title_box)
	move_child(_title_box, 1)
	var flores := UiStyle.heavy_label("Entre Flores", 118, UiStyle.ROSE, UiStyle.LEAF, 24)
	_title_box.add_child(flores)
	var codigo_y := 128
	_glitch_a = _code_label(Color(1, 0.2, 0.75, 0.7))
	_glitch_b = _code_label(Color(UiStyle.CYAN, 0.7))
	var codigo := _code_label(UiStyle.NEON)
	codigo.add_theme_color_override("font_outline_color", UiStyle.INK)
	codigo.add_theme_constant_override("outline_size", 22)
	for l in [_glitch_a, _glitch_b, codigo]:
		l.position = Vector2(150, codigo_y)
		_title_box.add_child(l)
	var sub := UiStyle.heavy_label(UiStyle.GAME_SUBTITLE, 28, Color(1, 1, 1), UiStyle.INK, 10)
	sub.position = Vector2(10, 268)
	_title_box.add_child(sub)
	_add_petals()

func _code_label(color: Color) -> Label:
	var l := Label.new()
	l.text = "y <Código/>"
	l.add_theme_font_override("font", UiStyle.mono_font())
	l.add_theme_font_size_override("font_size", 92)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	l.add_theme_constant_override("shadow_offset_y", 6)
	return l

## Pétalos que caen sobre el lado de las flores.
func _add_petals() -> void:
	var p := CPUParticles2D.new()
	p.amount = 26
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.position = Vector2(420, -20)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(460, 4)
	p.direction = Vector2(0.4, 1)
	p.spread = 25.0
	p.gravity = Vector2(10, 22)
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 45.0
	p.angular_velocity_min = -90.0
	p.angular_velocity_max = 90.0
	p.scale_amount_min = 5.0
	p.scale_amount_max = 9.0
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 0.5, 0.68, 0.95))
	grad.set_color(1, Color(1, 0.75, 0.85, 0.0))
	p.color_ramp = grad
	add_child(p)
	move_child(p, 1)

func _process(delta: float) -> void:
	if _title_box == null:
		return
	_t += delta
	_title_box.position.y = 60 + sin(_t * 1.4) * 6.0
	# glitch: cada cierto tiempo las copias de color se separan un instante
	_glitch_timer -= delta
	var amp := 5.0
	if _glitch_timer < 0.0:
		amp = 16.0
		if _glitch_timer < -0.12:
			_glitch_timer = randf_range(1.5, 3.5)
	_glitch_a.position = Vector2(150 - amp, 128 + sin(_t * 30) * (2 if amp > 6 else 0))
	_glitch_b.position = Vector2(150 + amp, 128 - sin(_t * 30) * (2 if amp > 6 else 0))

func _on_hover(button: Button, inside: bool) -> void:
	var target := Vector2(1.04, 1.04) if inside else Vector2.ONE
	create_tween().tween_property(button, "scale", target, 0.1)
	if inside:
		AudioManager.play_named("click", -10.0)

func _on_jugar_pressed() -> void:
	if GameManager.has_progress():
		HUD.show()
		get_tree().change_scene_to_file(GameManager.get_resume_scene())
	else:
		get_tree().change_scene_to_file("res://scenes/character_select/CharacterSelect.tscn")

func _on_ajustes_pressed() -> void:
	ajustes_panel.abrir()

func _on_acerca_de_pressed() -> void:
	acerca_panel.abrir()

func _on_salir_pressed() -> void:
	get_tree().quit()
