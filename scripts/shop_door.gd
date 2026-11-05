extends Node2D
class_name ShopDoor
## Porta (ou escada) interativa entre a loja e a oficina do andar de cima.
## A animação usa a spritesheet Doors_windows_animations do pacote CraftPix
## (6 quadros: fechada → abrindo → aberta → fechando).

const FRAME := Vector2i(32, 32)

var door_id := ""
var target_id := ""
var floor_name := ""
var action_text := ""
## Área (em coordenadas do mundo) onde o jogador precisa estar para usar a porta.
var zone := Rect2()
## Onde o jogador aparece ao chegar por esta porta.
var arrival := Vector2.ZERO

var _sprite: AnimatedSprite2D
var _hint: Label


static func create(config: Dictionary) -> ShopDoor:
	var door := ShopDoor.new()
	door.door_id = config["id"]
	door.target_id = config["target"]
	door.floor_name = config["floor"]
	door.action_text = config["action"]
	door.zone = config["zone"]
	door.arrival = config["arrival"]
	door.position = config.get("sprite_pos", door.zone.get_center())
	door.z_as_relative = false
	door.z_index = 30
	if config.has("texture"):
		door._build_sprite(load(config["texture"]))
	door._build_hint()
	return door


func _build_sprite(texture: Texture2D) -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("open")
	frames.set_animation_loop("open", false)
	frames.set_animation_speed("open", 12.0)
	for i in [0, 1, 2, 3]:
		frames.add_frame("open", _frame(texture, i))
	frames.add_animation("close")
	frames.set_animation_loop("close", false)
	frames.set_animation_speed("close", 12.0)
	for i in [3, 4, 5, 0]:
		frames.add_frame("close", _frame(texture, i))
	frames.remove_animation("default")
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.animation = "open"
	_sprite.frame = 0
	add_child(_sprite)


func _frame(texture: Texture2D, index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(index * FRAME.x, 0, FRAME.x, FRAME.y)
	return atlas


func _build_hint() -> void:
	_hint = UITheme.world_label(6)
	_hint.theme = GameState.ui_theme
	_hint.visible = false
	_hint.text = "[E] " + action_text
	add_child(_hint)
	# Dica logo acima da área de interação
	UITheme.place_world_label(_hint, zone.get_center() - position + Vector2(0, -12))


func contains(point: Vector2) -> bool:
	return zone.has_point(point)


func set_hint_visible(value: bool) -> void:
	_hint.visible = value


func play_open() -> void:
	if _sprite == null:
		return
	_sprite.play("open")
	await _sprite.animation_finished


func play_close() -> void:
	if _sprite == null:
		return
	_sprite.play("close")
	await _sprite.animation_finished
