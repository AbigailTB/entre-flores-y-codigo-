extends Control

signal closed

@onready var grid: GridContainer = $Card/VBox/Scroll/Grid
@onready var money_label: Label = $Card/VBox/Header/Money
@onready var msg_label: Label = $Card/VBox/Msg
@onready var close_button: Button = $CloseBtn

func _ready() -> void:
	add_to_group("modal_panel")
	hide()
	close_button.pressed.connect(_on_close_pressed)
	close_button.text = ""
	UiStyle.set_button_icon(close_button, "x", Color(1, 1, 1), 24)
	GameManager.money_changed.connect(_on_money_changed)

func _on_money_changed(_m: int) -> void:
	_update_money()

func _update_money() -> void:
	money_label.text = "$%d" % GameManager.money

func abrir() -> void:
	msg_label.text = ""
	_render()
	show()

func _style(color: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(16)
	s.set_border_width_all(2)
	s.border_color = border
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

func _render() -> void:
	_update_money()
	var title := get_node_or_null("Card/VBox/Header/Titulo")
	if title is Label:
		title.text = "Ropero de %s" % GameManager.player_name()
	for c in grid.get_children():
		c.queue_free()
	for o in OutfitManager.OUTFITS:
		var equipped: bool = GameManager.current_outfit == o["id"]
		var unlocked: bool = OutfitManager.is_unlocked(o["id"])
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(300, 250)
		var border := Color(1, 0.81, 0.29) if equipped else Color(1, 1, 1, 0.2)
		card.add_theme_stylebox_override("panel", _style(Color(0.14, 0.12, 0.24, 1), border))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var preview := TextureRect.new()
		preview.texture = load(OutfitManager.preview_path(o["id"]))
		preview.custom_minimum_size = Vector2(100, 220)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not unlocked:
			preview.modulate = Color(0.45, 0.45, 0.55, 1)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 10)
		var name_lbl := Label.new()
		name_lbl.text = o["nombre"]
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", Color(1, 0.86, 0.4))
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var price_lbl := Label.new()
		price_lbl.add_theme_font_size_override("font_size", 16)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 44)
		if equipped:
			price_lbl.text = "En uso"
			btn.text = "Equipado ✓"
			btn.disabled = true
		elif unlocked:
			price_lbl.text = "Desbloqueado"
			btn.text = "Equipar"
			btn.pressed.connect(_on_equip.bind(o["id"]))
		else:
			price_lbl.text = "🔒 $%d" % int(o["precio"])
			btn.text = "Comprar"
			btn.pressed.connect(_on_buy.bind(o["id"]))
		col.add_child(name_lbl)
		col.add_child(price_lbl)
		col.add_child(btn)
		row.add_child(preview)
		row.add_child(col)
		card.add_child(row)
		grid.add_child(card)

func _on_equip(outfit_id: String) -> void:
	AudioManager.play_named("click")
	OutfitManager.equip(outfit_id)
	msg_label.text = ""
	_render()

func _on_buy(outfit_id: String) -> void:
	var result := OutfitManager.buy(outfit_id)
	if result == "ok":
		AudioManager.play_named("dinero")
		msg_label.text = "¡Nueva ropa desbloqueada!"
		msg_label.add_theme_color_override("font_color", Color(0.5, 0.95, 0.6))
	else:
		AudioManager.play_named("incorrecto")
		var price := int(OutfitManager.find_outfit(outfit_id)["precio"])
		msg_label.text = "Te faltan $%d. Trabaja en la florería para ganar dinero." % (price - GameManager.money)
		msg_label.add_theme_color_override("font_color", Color(0.95, 0.5, 0.5))
	_render()

func _on_close_pressed() -> void:
	hide()
	closed.emit()
