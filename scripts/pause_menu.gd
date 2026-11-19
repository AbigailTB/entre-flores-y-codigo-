extends CanvasLayer

const BLOCKED_SCENES := [
	"res://scenes/main_menu/MainMenu.tscn",
	"res://scenes/intro/Intro.tscn",
]

@onready var continue_button: Button = $Card/VBox/ContinueBtn
@onready var menu_button: Button = $Card/VBox/MenuBtn
@onready var ajustes_button: Button = $Card/VBox/AjustesBtn
@onready var ajustes_panel: Control = $AjustesPanel
@onready var quit_button: Button = $Card/VBox/QuitBtn

func _ready() -> void:
	layer = 98
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	continue_button.pressed.connect(_on_continue_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	ajustes_button.pressed.connect(func(): ajustes_panel.abrir())
	quit_button.pressed.connect(_on_quit_pressed)
	_build_skill_ui()
	_build_progress_ui()
	continue_button.text = "Continuar"
	UiStyle.set_button_icon(continue_button, "play", UiStyle.INK, 24)
	ajustes_button.text = "Ajustes"
	UiStyle.set_button_icon(ajustes_button, "settings", UiStyle.INK, 24)
	menu_button.text = "Menú principal"
	UiStyle.set_button_icon(menu_button, "arrow-left", UiStyle.INK, 24)
	quit_button.text = "Salir"
	UiStyle.set_button_icon(quit_button, "power", UiStyle.INK, 24)

var _skill_popup: PanelContainer
var _skill_list: VBoxContainer

func _build_skill_ui() -> void:
	var btn := Button.new()
	btn.name = "SkillBtn"
	btn.text = "Habilidad"
	UiStyle.set_button_icon(btn, "zap", UiStyle.ROSE, 24)
	btn.custom_minimum_size = ajustes_button.custom_minimum_size
	for k in ["normal", "hover", "pressed"]:
		if ajustes_button.has_theme_stylebox_override(k):
			btn.add_theme_stylebox_override(k, ajustes_button.get_theme_stylebox(k))
	btn.pressed.connect(_open_skills)
	var vbox := ajustes_button.get_parent()
	vbox.add_child(btn)
	vbox.move_child(btn, ajustes_button.get_index())
	_skill_popup = PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = UiStyle.PANEL
	st.set_corner_radius_all(20)
	st.set_border_width_all(3)
	st.border_color = UiStyle.NEON
	st.set_content_margin_all(18)
	_skill_popup.add_theme_stylebox_override("panel", st)
	_skill_popup.set_anchors_preset(Control.PRESET_CENTER)
	_skill_popup.custom_minimum_size = Vector2(560, 0)
	_skill_popup.position = Vector2(-280, -200)
	_skill_list = VBoxContainer.new()
	_skill_list.add_theme_constant_override("separation", 8)
	_skill_popup.add_child(_skill_list)
	_skill_popup.hide()
	add_child(_skill_popup)

var _progress_popup: PanelContainer
var _progress_list: VBoxContainer

func _build_progress_ui() -> void:
	var btn := Button.new()
	btn.name = "ProgressBtn"
	btn.text = "Mi avance"
	UiStyle.set_button_icon(btn, "book-open", UiStyle.CYAN, 24)
	btn.custom_minimum_size = ajustes_button.custom_minimum_size
	for k in ["normal", "hover", "pressed"]:
		if ajustes_button.has_theme_stylebox_override(k):
			btn.add_theme_stylebox_override(k, ajustes_button.get_theme_stylebox(k))
	btn.pressed.connect(_open_progress)
	var vbox := ajustes_button.get_parent()
	vbox.add_child(btn)
	vbox.move_child(btn, 1)
	_progress_popup = PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = UiStyle.PANEL
	st.set_corner_radius_all(20)
	st.set_border_width_all(3)
	st.border_color = UiStyle.NEON
	st.set_content_margin_all(16)
	_progress_popup.add_theme_stylebox_override("panel", st)
	_progress_popup.position = Vector2(140, 30)
	_progress_popup.custom_minimum_size = Vector2(1000, 0)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(980, 600)
	_progress_list = VBoxContainer.new()
	_progress_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_progress_list)
	_progress_popup.add_child(scroll)
	_progress_popup.hide()
	add_child(_progress_popup)

func _plabel(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _open_progress() -> void:
	AudioManager.play_named("click")
	for c in _progress_list.get_children():
		c.queue_free()
	var nxt := Career.next_rank_xp()
	var rank_txt := "Rango: %s · %d AURA" % [Career.rank_name(), GameManager.xp]
	if nxt > 0:
		rank_txt += "  (siguiente rango a los %d AURA)" % nxt
	_progress_list.add_child(_plabel("Avance de %s en la carrera de TI" % GameManager.player_name(), 24, UiStyle.NEON))
	_progress_list.add_child(_plabel(rank_txt + "   ·   💰 $%d" % GameManager.money, 17, UiStyle.CYAN))
	for c in Career.CUATRIS:
		var state := "✔ Aprobado" if Career.is_cuatri_passed(c["id"]) else ("▶ Cursando" if Career.is_cuatri_unlocked(c["id"]) else "Bloqueado")
		_progress_list.add_child(_plabel("%s  —  %s  ·  %s" % [c["nombre"], c["dificultad"], state], 19, UiStyle.YELLOW))
		for t in c["teachers"]:
			var info: Dictionary = Career.teacher(t)
			var mark := "✔" if GameManager.is_teacher_defeated(t) else ("▶" if Career.is_teacher_unlocked(t) else "×")
			var mat: String = info["materia"] if info["materia"] != "*" else "Examen final (todas las materias)"
			_progress_list.add_child(_plabel("      %s  %s · %s  ·  %d preguntas  ·  error = -%d ❤" % [mark, info["nombre"], mat, info["preguntas"], info["dano"]], 15, Color(0.92, 0.92, 0.98)))
	var names: Array = []
	for b in GameManager.badges:
		names.append(Career.badge_name(b))
	_progress_list.add_child(_plabel("Trofeos (%d): %s" % [names.size(), ", ".join(names) if names.size() > 0 else "aún ninguno — ¡aprueba a tu primer maestro!"], 16, Color(0.7, 1, 0.75)))
	var close := Button.new()
	close.text = "Cerrar"
	close.custom_minimum_size = Vector2(0, 44)
	close.pressed.connect(func(): _progress_popup.hide())
	_progress_list.add_child(close)
	_progress_popup.show()

func _open_skills() -> void:
	AudioManager.play_named("click")
	for c in _skill_list.get_children():
		c.queue_free()
	var title := Label.new()
	title.text = "Habilidad de %s" % GameManager.player_name()
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UiStyle.NEON)
	_skill_list.add_child(title)
	var current: String = Skills.current_skill()["id"]
	for s in Skills.skills_for(Skills.current_character()):
		var b := Button.new()
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 62)
		b.text = ("✔ " if s["id"] == current else "") + s["nombre"] + "\n" + s["desc"]
		b.pressed.connect(_choose_skill.bind(s["id"]))
		_skill_list.add_child(b)
	var close := Button.new()
	close.text = "Cerrar"
	close.custom_minimum_size = Vector2(0, 44)
	close.pressed.connect(func(): _skill_popup.hide())
	_skill_list.add_child(close)
	_skill_popup.show()

func _choose_skill(skill_id: String) -> void:
	AudioManager.play_named("correcto")
	GameManager.set_skill(skill_id)
	Skills.reset_uses()
	var scene := get_tree().current_scene
	if scene:
		Skills.on_scene_entered(scene.scene_file_path)
	var player := get_tree().get_first_node_in_group("player")
	if player and "speed" in player and "_base_speed" in player:
		player.speed = player._base_speed * Skills.speed_multiplier()
	HUD.refresh()
	_open_skills()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle()
		get_viewport().set_input_as_handled()

func _toggle() -> void:
	var current_scene := get_tree().current_scene
	if visible:
		_resume()
		return
	if current_scene and current_scene.scene_file_path in BLOCKED_SCENES:
		return
	_pause()

func _pause() -> void:
	get_tree().paused = true
	show()

func _resume() -> void:
	get_tree().paused = false
	if _skill_popup:
		_skill_popup.hide()
	if _progress_popup:
		_progress_popup.hide()
	hide()

func _on_continue_pressed() -> void:
	_resume()

func _on_menu_pressed() -> void:
	_resume()
	HUD.hide()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
