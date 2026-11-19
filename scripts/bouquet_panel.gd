extends Control

signal closed
signal solved(order_id: String, reward: int)

const MAX_FLOWERS := 14

var money_reward: int = 50
var current_order_id: String = "regular"
var requirements: Array = []
var sequence: Array = []
var _solved := false

@onready var titulo_label: Label = $RecipeCard/VBox/Titulo
@onready var recipe_list: VBoxContainer = $RecipeCard/VBox/RecipeList
@onready var grid: GridContainer = $Shelf/VBox/Scroll/Grid
@onready var flowers_root: Control = $BouquetArea/View/Flowers
@onready var feedback_label: Label = $Feedback
@onready var confirm_button: Button = $Buttons/ConfirmBtn
@onready var reset_button: Button = $Buttons/ResetBtn
@onready var undo_button: Button = $Buttons/UndoBtn
@onready var close_button: Button = $CloseBtn

func _ready() -> void:
	add_to_group("modal_panel")
	hide()
	confirm_button.pressed.connect(_on_confirm_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	undo_button.pressed.connect(_on_undo_pressed)
	close_button.pressed.connect(_on_close_pressed)
	_build_jars()

func _jar_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(14)
	s.set_border_width_all(2)
	s.border_color = Color(1, 1, 1, 0.55)
	return s

func _build_jars() -> void:
	for f in FlowerCatalog.FLOWERS:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(150, 132)
		btn.add_theme_stylebox_override("normal", _jar_style(Color(0.88, 0.96, 0.94, 0.92)))
		btn.add_theme_stylebox_override("hover", _jar_style(Color(1, 1, 0.9, 1)))
		btn.add_theme_stylebox_override("pressed", _jar_style(Color(0.8, 0.92, 0.86, 1)))
		var box := VBoxContainer.new()
		box.set_anchors_preset(Control.PRESET_FULL_RECT)
		box.offset_top = 6
		box.offset_bottom = -6
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		icon.texture = load(f["icon"])
		icon.custom_minimum_size = Vector2(0, 92)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var lbl := Label.new()
		lbl.text = f["nombre"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", Color(0.12, 0.25, 0.24))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(icon)
		box.add_child(lbl)
		btn.add_child(box)
		btn.pressed.connect(_on_flower_clicked.bind(f["id"]))
		grid.add_child(btn)

func abrir_pedido(reqs: Array, reward: int, titulo: String = "Pedido: Ramo especial", order_id: String = "regular") -> void:
	requirements = []
	for r in reqs:
		requirements.append(r.duplicate())
	money_reward = int(round(reward * Skills.floreria_multiplier()))
	current_order_id = order_id
	titulo_label.text = titulo
	sequence.clear()
	_solved = false
	feedback_label.text = ""
	_refresh(false)
	show()

func _count(flower_id: String) -> int:
	var n := 0
	for s in sequence:
		if s == flower_id:
			n += 1
	return n

func _refresh(pop_last: bool) -> void:
	for c in recipe_list.get_children():
		c.queue_free()
	var required_ids: Array = []
	for r in requirements:
		required_ids.append(r["id"])
		var have := _count(r["id"])
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 19)
		lbl.text = "%s: %d/%d" % [r["nombre"], have, r["requerido"]]
		if have == r["requerido"]:
			lbl.add_theme_color_override("font_color", Color(0.15, 0.5, 0.25))
		elif have > r["requerido"]:
			lbl.add_theme_color_override("font_color", Color(0.8, 0.25, 0.25))
		else:
			lbl.add_theme_color_override("font_color", Color(0.25, 0.18, 0.12))
		recipe_list.add_child(lbl)
	var extras := {}
	for s in sequence:
		if not required_ids.has(s):
			extras[s] = extras.get(s, 0) + 1
	for k in extras:
		var lbl2 := Label.new()
		lbl2.add_theme_font_size_override("font_size", 16)
		lbl2.add_theme_color_override("font_color", Color(0.8, 0.25, 0.25))
		lbl2.text = "Sobra: %s x%d" % [FlowerCatalog.get_flower(k)["nombre"], extras[k]]
		recipe_list.add_child(lbl2)
	_rebuild_bouquet(pop_last)

func _rebuild_bouquet(pop_last: bool) -> void:
	for c in flowers_root.get_children():
		c.queue_free()
	var n := sequence.size()
	for i in n:
		var t := TextureRect.new()
		t.texture = load(FlowerCatalog.get_flower(sequence[i])["pixel"])
		t.custom_minimum_size = Vector2(60, 90)
		t.size = Vector2(60, 90)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.pivot_offset = Vector2(30, 90)
		var f := 0.5
		if n > 1:
			f = float(i) / float(n - 1)
		t.rotation_degrees = 0.0
		if n > 1:
			t.rotation_degrees = lerpf(-38.0, 38.0, f)
		t.position = Vector2(245 - 30 + (f - 0.5) * 60.0, 196 - 90)
		flowers_root.add_child(t)
		if pop_last and i == n - 1:
			t.scale = Vector2(0.4, 0.4)
			create_tween().tween_property(t, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_flower_clicked(flower_id: String) -> void:
	if _solved or sequence.size() >= MAX_FLOWERS:
		return
	sequence.append(flower_id)
	AudioManager.play_named("flor")
	feedback_label.text = ""
	_refresh(true)

func _on_undo_pressed() -> void:
	if _solved or sequence.is_empty():
		return
	sequence.pop_back()
	feedback_label.text = ""
	_refresh(false)

func _on_reset_pressed() -> void:
	if _solved:
		return
	sequence.clear()
	feedback_label.text = ""
	_refresh(false)

func _matches() -> bool:
	var total_required := 0
	for r in requirements:
		total_required += r["requerido"]
		if _count(r["id"]) != r["requerido"]:
			return false
	return sequence.size() == total_required

func _on_confirm_pressed() -> void:
	if _solved:
		return
	if not _matches():
		AudioManager.play_named("incorrecto")
		feedback_label.text = "El ramo no está terminado correctamente."
		feedback_label.add_theme_color_override("font_color", Color(0.95, 0.5, 0.5))
		return
	_solved = true
	feedback_label.text = "¡Ramo terminado correctamente! Ganaste $%d." % money_reward
	feedback_label.add_theme_color_override("font_color", Color(0.5, 0.95, 0.6))
	GameManager.add_money(money_reward)
	AudioManager.play_named("dinero")
	solved.emit(current_order_id, money_reward)

func _on_close_pressed() -> void:
	hide()
	closed.emit()
