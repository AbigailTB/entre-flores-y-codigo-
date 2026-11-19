extends CanvasLayer
## HUD: dinero, firmas, habilidad, cuatrimestre y AURA; y la barra de corazones
## arriba al centro mientras hay un reto con un maestro.

const HEART_FULL := preload("res://assets/ui/pixel/corazon.png")
const HEART_EMPTY := preload("res://assets/ui/pixel/corazon_vacio.png")
const STAR := preload("res://assets/ui/pixel/estrella.png")

@onready var panel: Panel = $Panel

var hearts_box: HBoxContainer
var hearts_bg: PanelContainer
var _hearts: Array = []
var _hearts_shown := 0
var _chips := {}          # id -> Label con el número
var _chip_row: HBoxContainer

func _ready() -> void:
	layer = 90
	panel.hide()           # el panel viejo de texto ya no se usa
	_chip_row = HBoxContainer.new()
	_chip_row.position = Vector2(18, 16)
	_chip_row.add_theme_constant_override("separation", 10)
	add_child(_chip_row)
	_add_chip("money", "coins", UiStyle.YELLOW, "Dinero")
	_add_chip("firmas", "pen-line", UiStyle.CYAN, "Firmas del profe Efrén")
	_add_chip("aura", "star", UiStyle.YELLOW, "AURA")
	_add_chip("cuatri", "graduation-cap", UiStyle.NEON, "Cuatrimestre actual")
	_add_chip("skill", "zap", UiStyle.ROSE, "Usos de tu habilidad en este salón")
	_build_hearts()
	GameManager.money_changed.connect(_on_changed)
	GameManager.challenge_completed.connect(_on_changed)
	GameManager.xp_changed.connect(_on_changed)
	GameManager.career_changed.connect(_on_changed)
	Skills.uses_changed.connect(_on_changed)
	_refresh()

## Ficha compacta: ícono de Lucide + número.
func _add_chip(id: String, icon_name: String, color: Color, tip: String) -> void:
	var chip := PanelContainer.new()
	var st := UiStyle.box(Color(0.04, 0.06, 0.1, 0.86), Color(color, 0.85), 22, 2, 0)
	st.content_margin_left = 10
	st.content_margin_right = 14
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	chip.add_theme_stylebox_override("panel", st)
	chip.tooltip_text = tip
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var ic := TextureRect.new()
	ic.texture = UiStyle.icon(icon_name)
	ic.custom_minimum_size = Vector2(24, 24)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.modulate = color
	row.add_child(ic)
	var l := UiStyle.heavy_label("0", 20, Color(1, 1, 1), UiStyle.INK, 6)
	l.add_theme_constant_override("shadow_offset_y", 2)
	row.add_child(l)
	chip.add_child(row)
	_chip_row.add_child(chip)
	_chips[id] = l

func _build_hearts() -> void:
	hearts_bg = PanelContainer.new()
	hearts_bg.add_theme_stylebox_override("panel", UiStyle.box(Color(0.04, 0.06, 0.1, 0.85), UiStyle.RED, 16, 3, 10))
	hearts_box = HBoxContainer.new()
	hearts_box.add_theme_constant_override("separation", 8)
	hearts_bg.add_child(hearts_box)
	add_child(hearts_bg)
	hearts_bg.hide()

func _on_changed(_arg = null) -> void:
	_refresh()

func refresh() -> void:
	_refresh()

## Muestra los corazones arriba al centro (durante un reto).
func show_hearts(current: int, maximum: int) -> void:
	if _hearts.size() != maximum:
		for c in hearts_box.get_children():
			c.queue_free()
		_hearts.clear()
		for i in maximum:
			var tr := TextureRect.new()
			tr.custom_minimum_size = Vector2(52, 44)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			hearts_box.add_child(tr)
			_hearts.append(tr)
	var lost := _hearts_shown > current and hearts_bg.visible
	for i in maximum:
		_hearts[i].texture = HEART_FULL if i < current else HEART_EMPTY
	_hearts_shown = current
	hearts_bg.show()
	await get_tree().process_frame
	hearts_bg.reset_size()
	var vp := get_viewport().get_visible_rect().size
	hearts_bg.position = Vector2((vp.x - hearts_bg.size.x) / 2, 14)
	if lost:
		var base := hearts_bg.position
		var tw := create_tween()
		for k in 6:
			tw.tween_property(hearts_bg, "position", base + Vector2(10 if k % 2 == 0 else -10, 0), 0.04)
		tw.tween_property(hearts_bg, "position", base, 0.04)
		hearts_bg.modulate = Color(1, 0.5, 0.5)
		create_tween().tween_property(hearts_bg, "modulate", Color.WHITE, 0.4)

func hide_hearts() -> void:
	hearts_bg.hide()
	_hearts_shown = 0

func _refresh() -> void:
	_chips["money"].text = "$%d" % GameManager.money
	_chips["firmas"].text = "%d/%d" % [GameManager.get_firmas_count(), GameManager.TOTAL_FIRMAS]
	var has := GameManager.has_character()
	for id in ["aura", "cuatri", "skill"]:
		_chips[id].get_parent().get_parent().visible = has
	if not has:
		return
	_chips["aura"].text = str(GameManager.xp)
	var cur: Dictionary = Career.current_cuatri()
	_chips["cuatri"].text = "Fin" if Career.career_finished() else ("%d°" % int(cur["id"]) if int(cur["id"]) < 5 else "Final")
	var s: Dictionary = Skills.current_skill()
	var skill_chip: Control = _chips["skill"].get_parent().get_parent()
	skill_chip.tooltip_text = "%s: %s" % [s["nombre"], s["desc"]]
	if int(s.get("usos", 0)) > 0:
		_chips["skill"].text = "x%d" % Skills.uses_left()
	else:
		_chips["skill"].text = "ON"
