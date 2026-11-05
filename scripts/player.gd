extends CharacterBody2D

signal interaction_requested

const WALK_SPEED := 90.0
const RUN_SPEED := 155.0
const FRAME_SIZE := Vector2i(32, 32)
const WALK_FRAMES := 12
const IDLE_FRAMES := [0, 2, 4, 6]
const BASE_SPRITE_Y := -10.0
const WALK_BOB_AMPLITUDE := 1.8
const WALK_BOB_SPEED := 18.0
const RUN_BOB_SPEED := 26.0
const FOOTSTEP_FRAMES := [0, 6]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var movement_enabled := true
var _facing := Vector2.DOWN
var _current_anim := ""


func _ready() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_sprite_frames()
	sprite.frame_changed.connect(_on_sprite_frame_changed)
	_set_animation("idle")


func _physics_process(_delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_walk_bob(Vector2.ZERO, WALK_SPEED)
		return

	var input := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input.length_squared() > 1.0:
		input = input.normalized()

	var speed := RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	velocity = input * speed
	move_and_slide()
	global_position = global_position.round()
	_update_walk_bob(input, speed)
	_update_animation(input, speed)


func _unhandled_input(event: InputEvent) -> void:
	if not movement_enabled:
		return
	if event.is_action_pressed("interact"):
		interaction_requested.emit()


func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled
	if not enabled:
		_set_animation("idle")


func play_interact() -> void:
	if not sprite.sprite_frames.has_animation("interact"):
		return
	sprite.flip_h = false
	sprite.flip_v = false
	_set_animation("interact")
	await sprite.animation_finished
	_set_animation("idle")


func play_sell_action() -> void:
	await play_interact()


func _build_sprite_frames() -> void:
	var texture: Texture2D = load("res://assets/craftpix/characters/Customer.png")
	var frames := SpriteFrames.new()

	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	for frame_index in IDLE_FRAMES:
		frames.add_frame("idle", _make_frame(texture, frame_index), 0.45)

	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	for i in WALK_FRAMES:
		frames.add_frame("walk", _make_frame(texture, i), 0.11)

	frames.add_animation("run")
	frames.set_animation_loop("run", true)
	for i in WALK_FRAMES:
		frames.add_frame("run", _make_frame(texture, i), 0.07)

	frames.add_animation("interact")
	frames.set_animation_loop("interact", false)
	for i in range(4, 8):
		frames.add_frame("interact", _make_frame(texture, i), 0.16)

	sprite.sprite_frames = frames


func _make_frame(texture: Texture2D, index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(index * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
	return atlas


func _apply_facing_flip(direction: String) -> void:
	match direction:
		"up":
			sprite.flip_h = false
			sprite.flip_v = false
		"left":
			sprite.flip_h = true
			sprite.flip_v = false
		_:
			sprite.flip_h = false
			sprite.flip_v = false


func _update_animation(input: Vector2, speed: float) -> void:
	if input == Vector2.ZERO:
		_facing = _facing if _facing != Vector2.ZERO else Vector2.DOWN
		_apply_facing_flip(_direction_name(_facing))
		_set_animation("idle")
		return

	_facing = input
	var anim := "run" if speed > WALK_SPEED + 1.0 else "walk"
	_apply_facing_flip(_direction_name(input))
	_set_animation(anim)


func _update_walk_bob(input: Vector2, speed: float) -> void:
	if input == Vector2.ZERO:
		sprite.position.y = BASE_SPRITE_Y
		return

	var bob_speed := RUN_BOB_SPEED if speed > WALK_SPEED + 1.0 else WALK_BOB_SPEED
	var phase := float(Time.get_ticks_msec()) / 1000.0 * bob_speed
	sprite.position.y = BASE_SPRITE_Y + sin(phase) * WALK_BOB_AMPLITUDE


func _set_animation(anim_name: String) -> void:
	if _current_anim == anim_name and sprite.is_playing():
		return
	_current_anim = anim_name
	sprite.play(anim_name)


func _direction_name(input: Vector2) -> String:
	if abs(input.x) > abs(input.y):
		return "right" if input.x > 0.0 else "left"
	return "down" if input.y > 0.0 else "up"


func _on_sprite_frame_changed() -> void:
	if _current_anim != "walk" and _current_anim != "run":
		return
	if sprite.frame not in FOOTSTEP_FRAMES:
		return
	var volume_db := -14.0 if _current_anim == "walk" else -11.0
	AudioManager.play_sfx("footstep", volume_db, randf_range(0.9, 1.1))
