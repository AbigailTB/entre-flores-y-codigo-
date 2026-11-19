extends Control

signal completado
signal closed

const CLIENTES := ["Ana Torres", "Carlos Méndez", "Familia Pérez"]
const TIPOS := [
	{"nombre": "Ramo Romántico", "reqs": [{"id": "rosa_roja", "nombre": "Rosa roja", "requerido": 4, "actual": 0}]},
	{"nombre": "Ramo Primaveral", "reqs": [{"id": "margarita", "nombre": "Margarita", "requerido": 3, "actual": 0}, {"id": "girasol", "nombre": "Girasol", "requerido": 2, "actual": 0}]},
	{"nombre": "Ramo Mixto", "reqs": [{"id": "rosa_roja", "nombre": "Rosa roja", "requerido": 2, "actual": 0}, {"id": "margarita", "nombre": "Margarita", "requerido": 2, "actual": 0}, {"id": "girasol", "nombre": "Girasol", "requerido": 2, "actual": 0}]},
]

@onready var page_cliente: Control = $Card/PageCliente
@onready var page_tipo: Control = $Card/PageTipo
@onready var page_flores: Control = $Card/PageFlores
@onready var page_resumen: Control = $Card/PageResumen

@onready var cliente_list: VBoxContainer = $Card/PageCliente/VBox/List
@onready var tipo_list: VBoxContainer = $Card/PageTipo/VBox/List
@onready var recipe_list: VBoxContainer = $Card/PageFlores/VBox/RecipeList
@onready var jar_rosa: Button = $Card/PageFlores/VBox/Shelf/JarRosa
@onready var jar_margarita: Button = $Card/PageFlores/VBox/Shelf/JarMargarita
@onready var jar_girasol: Button = $Card/PageFlores/VBox/Shelf/JarGirasol
@onready var flores_feedback: Label = $Card/PageFlores/VBox/Feedback
@onready var flores_confirm_btn: Button = $Card/PageFlores/VBox/ConfirmBtn

@onready var resumen_label: Label = $Card/PageResumen/VBox/ResumenLabel
@onready var resumen_confirm_btn: Button = $Card/PageResumen/VBox/ConfirmBtn

@onready var close_button: Button = $CloseBtn

var cliente_elegido: String = ""
var tipo_elegido: Dictionary = {}
var requirements: Array = []
var _requirement_labels: Dictionary = {}

func _ready() -> void:
	add_to_group("modal_panel")
	hide()
	close_button.pressed.connect(_on_close_pressed)
	jar_rosa.pressed.connect(_on_flower_clicked.bind("rosa_roja"))
	jar_margarita.pressed.connect(_on_flower_clicked.bind("margarita"))
	jar_girasol.pressed.connect(_on_flower_clicked.bind("girasol"))
	flores_confirm_btn.pressed.connect(_on_flores_confirm_pressed)
	resumen_confirm_btn.pressed.connect(_on_resumen_confirm_pressed)
	_build_cliente_list()
	_build_tipo_list()

func abrir() -> void:
	cliente_elegido = ""
	tipo_elegido = {}
	requirements = []
	_show_page(page_cliente)
	show()

func _build_cliente_list() -> void:
	for c in CLIENTES:
		var btn := Button.new()
		btn.text = c
		btn.custom_minimum_size = Vector2(0, 50)
		btn.pressed.connect(_on_cliente_selected.bind(c))
		cliente_list.add_child(btn)

func _on_cliente_selected(nombre: String) -> void:
	cliente_elegido = nombre
	_show_page(page_tipo)

func _build_tipo_list() -> void:
	for t in TIPOS:
		var btn := Button.new()
		btn.text = t["nombre"]
		btn.custom_minimum_size = Vector2(0, 50)
		btn.pressed.connect(_on_tipo_selected.bind(t))
		tipo_list.add_child(btn)

func _on_tipo_selected(tipo: Dictionary) -> void:
	tipo_elegido = tipo
	requirements = []
	for r in tipo["reqs"]:
		requirements.append(r.duplicate())
	_render_requirements()
	flores_feedback.text = ""
	_show_page(page_flores)

func _render_requirements() -> void:
	for child in recipe_list.get_children():
		child.queue_free()
	_requirement_labels.clear()
	for r in requirements:
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 18)
		recipe_list.add_child(lbl)
		_requirement_labels[r["id"]] = lbl
		_update_requirement_label(r)

func _update_requirement_label(r: Dictionary) -> void:
	var lbl: Label = _requirement_labels[r["id"]]
	lbl.text = "%s: %d/%d" % [r["nombre"], r["actual"], r["requerido"]]
	if r["actual"] >= r["requerido"]:
		lbl.add_theme_color_override("font_color", Color(0.15, 0.5, 0.25))
	else:
		lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

func _on_flower_clicked(flower_id: String) -> void:
	for r in requirements:
		if r["id"] == flower_id:
			if r["actual"] < r["requerido"]:
				r["actual"] += 1
				_update_requirement_label(r)
			flores_feedback.text = ""
			return

func _on_flores_confirm_pressed() -> void:
	for r in requirements:
		if r["actual"] != r["requerido"]:
			flores_feedback.text = "Todavía falta completar el ramo."
			return
	resumen_label.text = "Cliente: %s\nRamo: %s\n\n¿Confirmar el pedido?" % [cliente_elegido, tipo_elegido["nombre"]]
	_show_page(page_resumen)

func _on_resumen_confirm_pressed() -> void:
	hide()
	completado.emit()

func _show_page(page: Control) -> void:
	page_cliente.hide()
	page_tipo.hide()
	page_flores.hide()
	page_resumen.hide()
	page.show()

func _on_close_pressed() -> void:
	hide()
	closed.emit()
