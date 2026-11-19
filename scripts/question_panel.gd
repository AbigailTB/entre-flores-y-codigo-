extends Control

signal question_finished(was_correct: bool, points: int)
## Se cerró la pregunta con la X (o Esc) sin responder / sin continuar.
signal question_cancelled
## Se eligió una respuesta definitiva (antes de "Continuar").
signal answered(was_correct: bool)

@onready var header_label: Label = $Card/VBox/Header
@onready var enunciado_label: Label = $Card/VBox/Enunciado
@onready var options_box: VBoxContainer = $Card/VBox/Options
@onready var feedback_label: Label = $Card/VBox/Feedback
@onready var skill_button: Button = $Card/VBox/SkillBtn
@onready var continue_button: Button = $Card/VBox/ContinueBtn

var _current_question
var _answered := false
var _last_correct := false
var _second_chance_used := false
var _asker := ""
var status_label: Label
var face_rect: TextureRect
var code_box: PanelContainer
var code_text: RichTextLabel
var hint_label: Label
var feedback_rich: RichTextLabel
## Texto que explica qué pasa al fallar (lo pone el maestro, p. ej. "pierdes 2 corazones").
var penalty_hint := ""

const LETTERS := ["A", "B", "C", "D", "E", "F"]
const KEYWORDS := ["def", "return", "for", "in", "if", "elif", "else", "while", "print", "class", "import",
	"from", "let", "const", "var", "function", "fun", "val", "SELECT", "FROM", "WHERE", "JOIN", "ON",
	"GROUP", "BY", "ORDER", "INSERT", "INTO", "VALUES", "UPDATE", "SET", "COUNT", "AND", "OR", "NOT",
	"null", "None", "True", "False", "true", "false", "new", "void", "int", "String", "git", "await", "async"]

## Cara del profe en la esquina de la tarjeta (null = sin cara).
func set_face(tex: Texture2D) -> void:
	face_rect.texture = tex
	face_rect.visible = tex != null
	if tex:
		face_rect.pivot_offset = face_rect.size / 2
		face_rect.scale = Vector2(1.15, 1.15)
		create_tween().tween_property(face_rect, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)

## Línea extra bajo el encabezado (corazones y avance del reto). Vacío = se oculta.
func set_status(text: String) -> void:
	status_label.text = text
	status_label.visible = text != ""

func _ready() -> void:
	add_to_group("modal_panel")
	hide()
	continue_button.pressed.connect(_on_continue_pressed)
	continue_button.hide()
	skill_button.pressed.connect(_on_skill_pressed)
	status_label = Label.new()
	status_label.name = "Status"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", UiStyle.YELLOW)
	header_label.get_parent().add_child(status_label)
	header_label.get_parent().move_child(status_label, header_label.get_index() + 1)
	status_label.hide()
	UiUtil.add_close_button($Card, cancel)
	face_rect = TextureRect.new()
	face_rect.name = "Face"
	face_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face_rect.position = Vector2(16, 12)
	face_rect.size = Vector2(92, 92)
	$Card.add_child(face_rect)
	face_rect.hide()
	_build_code_box()
	_build_feedback()
	var card := $Card as Control
	card.offset_left = -390
	card.offset_right = 390
	card.offset_top = -280
	card.offset_bottom = 352
	var vb := $Card/VBox as VBoxContainer
	vb.add_theme_constant_override("separation", 8)
	vb.offset_top = 22
	vb.offset_bottom = -18
	options_box.add_theme_constant_override("separation", 6)

func _build_code_box() -> void:
	var vbox := enunciado_label.get_parent()
	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 15)
	hint_label.add_theme_color_override("font_color", UiStyle.MUTED)
	vbox.add_child(hint_label)
	vbox.move_child(hint_label, enunciado_label.get_index() + 1)
	code_box = PanelContainer.new()
	code_box.add_theme_stylebox_override("panel", UiStyle.box(Color(0.02, 0.03, 0.05, 1), Color(UiStyle.CYAN, 0.5), 10, 2, 12))
	code_text = RichTextLabel.new()
	code_text.bbcode_enabled = true
	code_text.fit_content = true
	code_text.scroll_active = false
	code_text.add_theme_font_override("normal_font", UiStyle.mono_font())
	code_text.add_theme_font_size_override("normal_font_size", 18)
	code_box.add_child(code_text)
	vbox.add_child(code_box)
	vbox.move_child(code_box, hint_label.get_index() + 1)
	code_box.hide()

func _build_feedback() -> void:
	feedback_rich = RichTextLabel.new()
	feedback_rich.bbcode_enabled = true
	feedback_rich.fit_content = true
	feedback_rich.scroll_active = false
	feedback_rich.add_theme_font_size_override("normal_font_size", 16)
	feedback_rich.add_theme_font_size_override("bold_font_size", 16)
	feedback_label.get_parent().add_child(feedback_rich)
	feedback_label.get_parent().move_child(feedback_rich, feedback_label.get_index())
	feedback_label.hide()

## Colorea el código: palabras clave, cadenas, números y comentarios, con número de línea.
func _highlight(code: String) -> String:
	var out := []
	var lines := code.split("\n")
	var rx_str := RegEx.create_from_string("(\"[^\"]*\"|'[^']*')")
	var rx_num := RegEx.create_from_string("\\b(\\d+(\\.\\d+)?)\\b")
	for i in lines.size():
		var line: String = lines[i].replace("[", "[lb]")
		var comment := ""
		var cut := -1
		for mark in ["#", "--", "//"]:
			var pos := line.find(mark)
			if pos >= 0 and (cut < 0 or pos < cut):
				cut = pos
		if cut >= 0:
			comment = line.substr(cut)
			line = line.substr(0, cut)
		var strings := []
		for m in rx_str.search_all(line):
			strings.append(m.get_string())
		for k in strings.size():
			line = line.replace(strings[k], "@@%d@@" % k)
		line = rx_num.sub(line, "[color=#ff9e64]$1[/color]", true)
		for kw in KEYWORDS:
			var rx := RegEx.create_from_string("\\b" + kw + "\\b")
			line = rx.sub(line, "[color=#ff6ac1]" + kw + "[/color]", true)
		for k in strings.size():
			line = line.replace("@@%d@@" % k, "[color=#ffd23f]" + strings[k] + "[/color]")
		if comment != "":
			line += "[color=#6b7a90]" + comment + "[/color]"
		out.append("[color=#55617a]%2d[/color]  %s" % [i + 1, line])
	return "\n".join(out)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		cancel()
		get_viewport().set_input_as_handled()

## Cerrar sin terminar: no cuenta como error ni como acierto.
func cancel() -> void:
	if not visible:
		return
	AudioManager.play_named("click")
	if _answered:
		# ya respondió: cerrar equivale a "Continuar"
		_on_continue_pressed()
		return
	set_status("")
	hide()
	question_cancelled.emit()

## asker: nombre de quien pregunta (p. ej. "Profa. Yuls"), opcional.
func show_question(question, asker: String = "") -> void:
	_current_question = question
	_asker = asker
	_answered = false
	_second_chance_used = false
	feedback_label.text = ""
	continue_button.hide()
	var tipo: String = question.get("tipo") if question.get("tipo") else "Pregunta"
	var icono := "Acertijo" if tipo == "Acertijo" else "Pregunta"
	var partes: Array = [icono, question.materia]
	if asker != "":
		partes.insert(0, asker)
	header_label.text = "  ·  ".join(partes)
	enunciado_label.text = question.enunciado
	set_face(null)
	var code: String = question.get("codigo") if question.get("codigo") else ""
	code_box.visible = code != ""
	if code != "":
		code_text.text = _highlight(code)
	var en: String = question.enunciado.to_lower()
	if en.contains("línea"):
		hint_label.text = "Lee el código línea por línea y elige dónde está el error."
	elif code != "":
		hint_label.text = "Lee el código con calma y elige la respuesta correcta."
	else:
		hint_label.text = "Elige la respuesta correcta."
	feedback_rich.text = ""

	for child in options_box.get_children():
		options_box.remove_child(child)
		child.queue_free()

	for i in question.opciones.size():
		var btn := Button.new()
		btn.text = "%s)  %s" % [LETTERS[i], question.opciones[i]]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 38)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_option_pressed.bind(i, btn))
		options_box.add_child(btn)

	_refresh_skill_button()
	show()

func _refresh_skill_button() -> void:
	var skill: Dictionary = Skills.current_skill()
	if skill["tipo"] != "activa":
		skill_button.hide()
		return
	skill_button.show()
	var left := Skills.uses_left()
	skill_button.text = "%s  (%d uso%s en este salón)" % [skill["nombre"], left, "" if left == 1 else "s"]
	skill_button.disabled = _answered or left <= 0

func _on_skill_pressed() -> void:
	if _answered or not Skills.consume():
		return
	AudioManager.play_named("flor")
	var correct: int = _current_question.respuesta_correcta
	if Skills.has("descarte"):
		var wrong: Array = []
		for i in options_box.get_child_count():
			if i != correct and not options_box.get_child(i).disabled:
				wrong.append(i)
		wrong.shuffle()
		for i in wrong.slice(0, 2):
			var b: Button = options_box.get_child(i)
			b.disabled = true
			b.modulate = Color(1, 1, 1, 0.3)
		feedback_rich.text = "[color=#ff6ac1]Descarte floral:[/color] se quitaron dos opciones incorrectas."
	elif Skills.has("debug"):
		var b: Button = options_box.get_child(correct)
		b.modulate = Color(0.55, 1, 0.65)
		feedback_rich.text = "[color=#3dff8a]Modo debug:[/color] la respuesta correcta está marcada en verde."
	_refresh_skill_button()
	skill_button.disabled = true

func _on_option_pressed(index: int, btn: Button) -> void:
	if _answered:
		return
	var correct: bool = index == _current_question.respuesta_correcta

	# Habilidad pasiva de Aby: segunda oportunidad (1 vez por salón)
	if not correct and not _second_chance_used and Skills.has("segunda") and Skills.uses_left() > 0:
		Skills.consume()
		_second_chance_used = true
		AudioManager.play_named("incorrecto")
		btn.disabled = true
		btn.modulate = Color(0.95, 0.4, 0.4, 0.6)
		feedback_rich.text = "[color=#ff6ac1]Segunda oportunidad:[/color] la opción %s no era. Inténtalo otra vez, no pierdes nada." % LETTERS[index]
		return

	_answered = true
	_last_correct = correct
	for child in options_box.get_children():
		child.disabled = true
	skill_button.disabled = true

	AudioManager.play_named("correcto" if correct else "incorrecto")
	answered.emit(correct)
	var rc: int = _current_question.respuesta_correcta
	var right_txt := "%s) %s" % [LETTERS[rc], _current_question.opciones[rc]]
	if correct:
		btn.modulate = Color(0.4, 0.9, 0.5)
		var premio := reward()
		feedback_rich.text = "[b][color=#3dff8a]✓ ¡Correcto![/color][/b]  +$%d\n[color=#9fb0c8]Por qué:[/color] %s" % [premio, _current_question.explicacion]
	else:
		btn.modulate = Color(0.95, 0.4, 0.4)
		var correct_btn: Button = options_box.get_child(rc)
		correct_btn.modulate = Color(0.4, 0.9, 0.5)
		var lost := ("   [color=#ff4d5e](%s)[/color]" % penalty_hint) if penalty_hint != "" else ""
		feedback_rich.text = "[b][color=#ff4d5e]✗ Incorrecto.[/color][/b] Elegiste [color=#ff4d5e]%s) %s[/color]%s\n[b][color=#3dff8a]✓ La correcta es:[/color][/b] %s\n[color=#9fb0c8]Por qué:[/color] %s" % [LETTERS[index], _current_question.opciones[index], lost, right_txt, _current_question.explicacion]

	continue_button.show()

## Dinero que da una respuesta correcta (afectado por la habilidad elegida).
func reward() -> int:
	return int(round(_current_question.puntos * Skills.answer_money_multiplier()))

func _on_continue_pressed() -> void:
	var points: int = _current_question.puntos if _last_correct else 0
	if _last_correct:
		GameManager.add_money(reward())
	set_status("")
	penalty_hint = ""
	hide()
	question_finished.emit(_last_correct, points)
