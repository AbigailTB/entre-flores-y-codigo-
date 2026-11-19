extends Area2D

@export var portrait: Texture2D
@export var voice: String = "voice_josmar"
@export var talk_texture: Texture2D
@export var bob_amplitude: float = 0.0
@export var bob_speed: float = 3.0

const TIPS := [
	"Si te trabas en un reto, pregúntale a Pétalo. Siempre tiene una buena pista.",
	"Con el dinero que ganas en la florería puedes comprar ropa nueva en el ropero.",
	"Los retos están en los escritorios con una estrella. ¡Cada uno vale una firma!",
	"Doña Flora paga muy bien los ramos bien armados. Fíjate en cada flor del pedido.",
	"El profesor Efrén no regala firmas, pero tampoco es tan estricto como parece.",
]

@onready var sprite: Sprite2D = get_node_or_null("Sprite")

var _met := false
var _used := false
var _base_y := 0.0
var _idle_texture: Texture2D
var _t := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if GameManager.character == "josh":
		_become_aby()
	if sprite:
		_base_y = sprite.position.y
		_idle_texture = sprite.texture
	DialogueBox.dialogue_finished.connect(_on_dialogue_finished)

## Si se juega con Josmar, la compañera que da consejos es Aby.
func _become_aby() -> void:
	voice = ""
	talk_texture = null
	portrait = load("res://assets/portraits/face_happy.png")
	if sprite:
		sprite.texture = load("res://assets/sprites/player/walk_down_1.png")
		sprite.scale = Vector2(0.36, 0.36)
		sprite.offset = Vector2(0, -174)
	var label := get_node_or_null("Label") as Label
	if label:
		label.text = "Aby"

func _process(delta: float) -> void:
	if sprite and bob_amplitude > 0.0:
		_t += delta
		sprite.position.y = _base_y + sin(_t * bob_speed) * bob_amplitude

func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player"):
		return
	_used = true
	if sprite and talk_texture:
		sprite.texture = talk_texture
	DialogueBox.show_dialogue(GameManager.companion_name(), _build_lines(), portrait, voice, sprite)

func _on_dialogue_finished() -> void:
	if sprite and talk_texture:
		sprite.texture = _idle_texture

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_used = false

func _build_lines() -> Array:
	var lines: Array = []
	if not _met:
		_met = true
		lines.append("¡Hola, {p}! Soy %s, tu compañer%s de clase." % [GameManager.companion_name(), "a" if GameManager.character == "josh" else "o"])
	else:
		lines.append("¡Otra vez por aquí, {p}!")
	lines.append(_progress_hint())
	return lines

func _progress_hint() -> String:
	var gm := GameManager
	if gm.is_challenge_completed("reto_final"):
		return "¡Lo lograste, {p}! Estoy muy orgullos%s de ti." % ("a" if GameManager.character == "josh" else "o") + " ¡Felicidades por tu título!"
	if not gm.is_challenge_completed("reto_escuela_1") and not gm.is_challenge_completed("reto_escuela_2"):
		return "Empieza por los retos de los escritorios con estrella. El profesor Efrén te dará su firma."
	if gm.get_firmas_count() >= 3:
		return "Ya tienes las firmas necesarias. ¡Ve con Doña Flora y presenta tu proyecto final!"
	if not gm.is_challenge_completed("reto_floreria_1"):
		return "Doña Flora tiene un pedido especial para ti en la florería. También cuenta como firma."
	return TIPS[randi() % TIPS.size()]
