extends CharacterBody2D
class_name CustomerNPC
## Cliente que entra na loja, vai até o balcão, negocia e vai embora.
## A aparência muda conforme a personalidade (troca de paleta via shader).

signal player_entered
signal player_exited
signal arrived_at_counter

const FRAME_SIZE := Vector2i(32, 32)
const IDLE_FRAMES := [0, 2, 4, 6, 8, 10]
const TEXTURE_PATH := "res://assets/craftpix/characters/Customer.png"
const SHADER_PATH := "res://assets/shaders/palette_swap.gdshader"
const BASE_SPRITE_Y := -8.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_area: Area2D = $InteractArea
@onready var interaction_hint: Label = $InteractionHint

var profile_id := ""
var profile: Dictionary = {}
var waiting := false
var _player_near := false
var _walking := false
var _bubble: Label


func _ready() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	interaction_hint.visible = false
	# O "[E]" da cena é trocado por um rótulo nítido (ver UITheme.world_label).
	interaction_hint.queue_free()
	interaction_hint = UITheme.world_label(8)
	interaction_hint.theme = GameState.ui_theme
	interaction_hint.text = "[E]"
	interaction_hint.visible = false
	add_child(interaction_hint)
	UITheme.place_world_label(interaction_hint, Vector2(0, -26))
	_build_sprite_frames()
	sprite.play("idle")
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	_build_bubble()


func _process(_delta: float) -> void:
	if _walking:
		var phase := float(Time.get_ticks_msec()) / 1000.0 * 16.0
		sprite.position.y = BASE_SPRITE_Y - absf(sin(phase)) * 1.5
	else:
		sprite.position.y = BASE_SPRITE_Y


# ------------------------------------------------------------------ Perfil
func set_profile(id: String) -> void:
	profile_id = id
	profile = GameData.CUSTOMERS.get(id, {})
	sprite.material = make_material(profile.get("colors", {}))


static func make_material(colors: Dictionary) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	for key in ["hair", "cloak", "shirt"]:
		if colors.has(key):
			mat.set_shader_parameter(key, colors[key])
	return mat


## Retrato (primeiro quadro do sprite) para usar na interface.
static func make_portrait(colors: Dictionary, frame: int = 0) -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(TEXTURE_PATH)
	atlas.region = Rect2(frame * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
	var rect := TextureRect.new()
	rect.texture = atlas
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(96, 96)
	if not colors.is_empty():
		rect.material = make_material(colors)
	return rect


# --------------------------------------------------------------- Movimento
func enter_shop(from_pos: Vector2, to_pos: Vector2) -> void:
	waiting = false
	visible = true
	global_position = from_pos
	modulate.a = 0.0
	_walking = true
	sprite.play("idle")
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	tween.tween_property(self, "global_position", to_pos, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	_walking = false
	waiting = true
	var greetings: Array = profile.get("greetings", ["Olá!"])
	say(greetings[randi() % greetings.size()], 3.5)
	interaction_hint.visible = _player_near
	arrived_at_counter.emit()


func leave_shop(to_pos: Vector2) -> void:
	waiting = false
	interaction_hint.visible = false
	_walking = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", to_pos, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.9)
	await tween.finished
	_walking = false
	visible = false


# ------------------------------------------------------------- Falas/emotes
func _build_bubble() -> void:
	_bubble = UITheme.world_label(6, 96, true)
	_bubble.theme = GameState.ui_theme
	_bubble.visible = false
	add_child(_bubble)


func say(text: String, duration: float = 2.5) -> void:
	if _bubble == null:
		return
	_bubble.text = text
	_bubble.visible = true
	_bubble.size = Vector2.ZERO
	UITheme.place_world_label(_bubble, Vector2(0, -30))
	_bubble.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(duration)
	tween.tween_property(_bubble, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void: _bubble.visible = false)


func hide_bubble() -> void:
	if _bubble:
		_bubble.visible = false


# -------------------------------------------------------------- Interação
func is_player_near() -> bool:
	return _player_near


func play_idle() -> void:
	sprite.play("idle")
	interaction_hint.visible = _player_near and waiting


func play_interact() -> void:
	if not sprite.sprite_frames.has_animation("interact"):
		return
	interaction_hint.visible = false
	sprite.play("interact")
	await sprite.animation_finished
	play_idle()


func set_interaction_hint_visible(value: bool) -> void:
	interaction_hint.visible = value and waiting


func _on_body_entered(body: Node2D) -> void:
	# Correção: antes qualquer corpo (inclusive as paredes) acendia o "[E]".
	if not body.is_in_group("player"):
		return
	_player_near = true
	interaction_hint.visible = waiting
	player_entered.emit()


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_near = false
	interaction_hint.visible = false
	player_exited.emit()


func _build_sprite_frames() -> void:
	var texture: Texture2D = load(TEXTURE_PATH)
	var frames := SpriteFrames.new()

	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	for frame_index in IDLE_FRAMES:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(frame_index * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame("idle", atlas, 0.4)

	frames.add_animation("interact")
	frames.set_animation_loop("interact", false)
	for i in range(4, 8):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame("interact", atlas, 0.16)

	sprite.sprite_frames = frames
