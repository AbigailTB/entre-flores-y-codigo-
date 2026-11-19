extends CanvasLayer

signal closed_popup

const FIRMA_PATH := "res://assets/ui/firma.png"

@onready var card: Panel = $Card
@onready var sig: TextureRect = $Card/VBox/Clip/Signature
@onready var cover: ColorRect = $Card/VBox/Clip/Cover
@onready var counter_label: Label = $Card/VBox/Counter
@onready var continue_button: Button = $Card/VBox/ContinueBtn

func _ready() -> void:
	add_to_group("modal_panel")
	layer = 99
	hide()
	continue_button.pressed.connect(_on_continue_pressed)
	GameManager.challenge_completed.connect(_on_challenge_completed)
	if ResourceLoader.exists(FIRMA_PATH):
		sig.texture = load(FIRMA_PATH)

func _on_challenge_completed(_id: String) -> void:
	show_reward()

func show_reward() -> void:
	counter_label.text = "✍ Firmas: %d/%d" % [GameManager.get_firmas_count(), GameManager.TOTAL_FIRMAS]
	continue_button.hide()
	cover.offset_left = 0.0
	card.pivot_offset = card.size / 2.0
	card.scale = Vector2(0.6, 0.6)
	card.modulate.a = 0.0
	show()
	AudioManager.play_named("firma")
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(card, "modulate:a", 1.0, 0.25)
	t.chain().tween_property(cover, "offset_left", 440.0, 1.1).set_trans(Tween.TRANS_SINE)
	t.chain().tween_callback(continue_button.show)

func _on_continue_pressed() -> void:
	AudioManager.play_named("click")
	hide()
	closed_popup.emit()
