@tool
extends Node2D
## Cena da loja: controla o ciclo do dia (manhã no fornecedor → clientes no
## balcão → resumo do entardecer), a narrativa da avó e a interface do jogo.

const ZOOM := Vector2(3.2, 3.2)
## Centro da câmera em cada andar: a loja (balcão) e a oficina (andar de cima).
const FLOOR_CAMERA := {"loja": Vector2(144, 204), "oficina": Vector2(144, 96)}
const FLOOR_NAMES := {"loja": "Loja", "oficina": "Oficina (2º andar)"}
## Deslocamento da câmera quando o painel de negociação ocupa a direita da tela.
const CAMERA_PANEL_OFFSET := Vector2(88, 0)
const PLAYER_START := Vector2(144, 198)

## Colisões dos móveis (coordenadas do mundo). As paredes já vêm do TMX; aqui
## entram o balcão, as estantes de canto e os móveis da oficina, que antes
## podiam ser atravessados.
const FURNITURE_COLLIDERS := [
	# --- Loja (térreo)
	Rect2(48, 203, 192, 15),   # balcão de atendimento (parede a parede)
	Rect2(48, 203, 38, 52),    # estante de canto esquerda
	Rect2(204, 203, 36, 52),   # estante de canto direita
	# --- Oficina (andar de cima)
	Rect2(78, 94, 19, 11),     # carrinho de carvão
	Rect2(97, 84, 26, 13),     # lenha e vasos ao lado da forja
	Rect2(122, 78, 42, 11),    # base da forja
	Rect2(62, 116, 18, 12),    # vaso da planta da esquerda
	Rect2(62, 121, 26, 8),     # caixotes da esquerda
	Rect2(170, 108, 50, 14),   # bancada do mestre vidreiro
	Rect2(186, 117, 40, 12),   # caixotes da direita
]

## Portas e escada entre os andares. "zone" é onde Marco precisa estar para
## apertar E; "arrival" é onde ele aparece ao chegar pela porta.
const DOORS := [
	{
		"id": "loja_esquerda", "target": "oficina_escada", "floor": "loja",
		"action": "Subir para a oficina", "texture": "res://assets/craftpix/maps/door_anim_arch.png",
		"sprite_pos": Vector2(64, 176), "zone": Rect2(62, 192, 22, 11), "arrival": Vector2(72, 198),
	},
	{
		"id": "loja_direita", "target": "oficina_porta", "floor": "loja",
		"action": "Subir para a oficina", "texture": "res://assets/craftpix/maps/door_anim_arch.png",
		"sprite_pos": Vector2(224, 176), "zone": Rect2(204, 192, 22, 11), "arrival": Vector2(216, 198),
	},
	{
		"id": "oficina_escada", "target": "loja_esquerda", "floor": "oficina",
		"action": "Descer para a loja",
		"zone": Rect2(62, 96, 24, 14), "arrival": Vector2(72, 111),
	},
	{
		"id": "oficina_porta", "target": "loja_direita", "floor": "oficina",
		"action": "Descer para a loja", "texture": "res://assets/craftpix/maps/door_anim.png",
		"sprite_pos": Vector2(224, 80), "zone": Rect2(200, 96, 24, 12), "arrival": Vector2(212, 101),
	},
]

const MASTER_TIPS := [
	"Mestre Vidreiro: Compro areia por 1 e vendo o copo por 8. São 7 de lucro por copo!",
	"Mestre Vidreiro: Um quarto de desconto é 25%. Na Rua dos Vidreiros todo mundo fala assim.",
	"Mestre Vidreiro: Desconto demais vira prejuízo. Sempre confira quanto você pagou.",
	"Mestre Vidreiro: Tem cliente lá embaixo? O balcão não se atende sozinho, rapaz!",
]
const COUNTER_SPOT := Vector2(144, 232)
const ENTRANCE := Vector2(144, 266)
const SHOP_MASTER_POS := Vector2(196, 96)

@onready var world: Node2D = $World
@onready var player: CharacterBody2D = $World/Player
@onready var customer: CustomerNPC = $World/Customer
@onready var camera: Camera2D = $Camera2D
@onready var ui: CanvasLayer = $UI
@onready var trade_panel: Control = $UI/TradePanel
@onready var effects: CanvasLayer = $UI/EffectsLayer
@onready var map_root: Node2D = $World/MapRoot

@export var rebuild_map_in_editor := false

var _trade_open := false
var _busy := false
var _current_order: Dictionary = {}
var _last_customer_id := ""
var _customers_served := 0
var _day_total := 0
var _pending_story: Array = []
var _tint: CanvasModulate
var _floor := "loja"
var _doors: Dictionary = {}
var _changing_floor := false
var _master: AnimatedSprite2D
var _master_bubble: Label
var _master_tip_index := 0
var _master_near := false
var _fade: ColorRect

# HUD
var _day_label: Label
var _district_label: Label
var _money_label: Label
var _level_label: Label
var _xp_bar: ProgressBar
var _queue_label: Label
var _hint_label: Label
var _sound_button: Button
var _toast: Label
var _dialogue: DialogueBox
var _morning: MorningPanel
var _summary: DaySummaryPanel


func _ready() -> void:
	if Engine.is_editor_hint():
		_load_shop_map()
		return

	randomize()
	_load_shop_map()
	_build_furniture_colliders()
	_build_doors()
	_setup_shop_master()
	_build_hud()
	_build_overlays()

	_tint = CanvasModulate.new()
	world.add_child(_tint)

	player.add_to_group("player")
	player.global_position = PLAYER_START
	player.interaction_requested.connect(_on_player_interact)
	customer.visible = false
	customer.player_entered.connect(_update_hint)
	customer.player_exited.connect(_update_hint)
	trade_panel.resolved.connect(_on_trade_resolved)
	trade_panel.closed.connect(_on_trade_closed)
	GameState.money_changed.connect(_on_money_changed)
	GameState.level_up.connect(_on_level_up)

	camera.zoom = ZOOM
	camera.global_position = FLOOR_CAMERA["loja"]
	camera.position_smoothing_enabled = false
	camera.make_current()

	_refresh_hud()
	_day_loop()


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	if GameState.money_changed.is_connected(_on_money_changed):
		GameState.money_changed.disconnect(_on_money_changed)
	if GameState.level_up.is_connected(_on_level_up):
		GameState.level_up.disconnect(_on_level_up)


# ================================================================ Mapa
func _load_shop_map() -> void:
	ShopMapLoader.build(
		map_root,
		"res://assets/craftpix/maps/Interior.tmx",
		self if Engine.is_editor_hint() else null
	)
	player.z_as_relative = false
	customer.z_as_relative = false
	player.z_index = 120
	customer.z_index = 110


## Mestre vidreiro trabalhando na oficina (ambientação do andar de cima).
func _setup_shop_master() -> void:
	var texture: Texture2D = load("res://assets/craftpix/characters/Master_Idle.png")
	var frames := SpriteFrames.new()
	frames.add_animation("work")
	frames.set_animation_loop("work", true)
	for i in 12:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * 64, 0, 64, 80)
		frames.add_frame("work", atlas, 0.14)
	_master = AnimatedSprite2D.new()
	_master.name = "ShopMaster"
	_master.sprite_frames = frames
	_master.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_master.position = SHOP_MASTER_POS
	_master.z_as_relative = false
	_master.z_index = 100
	world.add_child(_master)
	_master.play("work")

	_master_bubble = UITheme.world_label(5.5, 110, true)
	_master_bubble.theme = GameState.ui_theme
	_master_bubble.visible = false
	world.add_child(_master_bubble)


# ============================================================ Física e portas
func _build_furniture_colliders() -> void:
	var body := StaticBody2D.new()
	body.name = "FurnitureColliders"
	world.add_child(body)
	for rect: Rect2 in FURNITURE_COLLIDERS:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = rect.get_center()
		body.add_child(shape)


## Usado pelas ferramentas de teste para desenhar as colisões sobre o mapa.
func debug_collision_rects() -> Array:
	var rects: Array = FURNITURE_COLLIDERS.duplicate()
	for door in DOORS:
		rects.append(door["zone"])
	return rects


func _build_doors() -> void:
	for config in DOORS:
		var door := ShopDoor.create(config)
		world.add_child(door)
		_doors[door.door_id] = door


func _door_under_player() -> ShopDoor:
	for door: ShopDoor in _doors.values():
		if door.floor_name == _floor and door.contains(player.global_position):
			return door
	return null


func _use_door(door: ShopDoor) -> void:
	if _changing_floor:
		return
	_changing_floor = true
	var target: ShopDoor = _doors[door.target_id]
	player.set_movement_enabled(false)
	door.set_hint_visible(false)
	AudioManager.play_sfx("footstep", -6.0, 0.7)
	await door.play_open()
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.22)
	await tween.finished
	door.play_close()

	_floor = target.floor_name
	player.global_position = target.arrival
	player.reset_physics_interpolation()
	camera.global_position = FLOOR_CAMERA[_floor]
	target.play_open()
	AudioManager.play_sfx("footstep", -6.0, 0.8)
	_refresh_hud()

	tween = create_tween()
	tween.tween_property(_fade, "color:a", 0.0, 0.25)
	await tween.finished
	await target.play_close()
	player.set_movement_enabled(true)
	_changing_floor = false
	if _floor == "loja" and customer.waiting:
		_toast_message("%s está esperando no balcão!" % GameData.CUSTOMERS[customer.profile_id]["name"], 1.6)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _hint_label == null:
		return
	var current := _door_under_player() if not _changing_floor and player.movement_enabled else null
	for door: ShopDoor in _doors.values():
		door.set_hint_visible(door == current)
	_update_master(_floor == "oficina" and not _changing_floor)


func _update_master(on_floor: bool) -> void:
	if _master == null:
		return
	# Marco passa por trás da bancada do mestre quando está acima dela.
	var behind := on_floor and player.global_position.y < 110 and absf(player.global_position.x - SHOP_MASTER_POS.x) < 36
	player.z_index = 95 if behind else 120
	var near := on_floor and player.global_position.distance_to(SHOP_MASTER_POS + Vector2(0, 8)) < 40
	if near and not _master_near:
		_master_bubble.text = MASTER_TIPS[_master_tip_index % MASTER_TIPS.size()]
		_master_tip_index += 1
		_master_bubble.size = Vector2.ZERO
		UITheme.place_world_label(_master_bubble, SHOP_MASTER_POS + Vector2(-20, -30))
		_master_bubble.visible = true
	elif not near and _master_near:
		_master_bubble.visible = false
	_master_near = near


# ============================================================ Ciclo do dia
func _day_loop() -> void:
	await get_tree().process_frame
	player.set_movement_enabled(false)
	if not GameState.story_seen.get("intro", false):
		await _play_story("intro")

	while is_inside_tree():
		GameState.start_day()
		_customers_served = 0
		_day_total = GameState.customers_per_day()
		_refresh_hud()
		player.set_movement_enabled(false)
		await _morning.show_morning()
		player.set_movement_enabled(true)
		_apply_district_look()
		_refresh_hud()
		_toast_message("%s abriu as portas!" % GameData.level_name(GameState.level))

		var total := _day_total
		for i in total:
			if not is_inside_tree():
				return
			await get_tree().create_timer(0.9 if i == 0 else 1.6).timeout
			await _serve_next_customer()
			_customers_served += 1
			_refresh_hud()

		await get_tree().create_timer(0.8).timeout
		player.set_movement_enabled(false)
		await _summary.show_summary()
		var needed_loan := GameState.end_day()
		_customers_served = 0
		_day_total = GameState.customers_per_day()
		_refresh_hud()
		if needed_loan:
			await _dialogue.play(GameData.STORY["loan"])
		while not _pending_story.is_empty():
			await _play_story(_pending_story.pop_front())
		if GameState.days_at_max_level >= GameData.FINALE_AFTER_DAYS_AT_MAX and not GameState.story_seen.get("finale", false):
			await _play_story("finale")


func _play_story(key: String) -> void:
	if GameState.story_seen.get(key, false):
		return
	await _dialogue.play(GameData.STORY[key])
	GameState.story_seen[key] = true
	GameState.save_game()


func _serve_next_customer() -> void:
	var customer_id := _pick_customer()
	_last_customer_id = customer_id
	customer.set_profile(customer_id)
	_current_order = ChallengeGenerator.generate(GameState.district, GameData.CUSTOMERS[customer_id], GameState.level)
	AudioManager.play_sfx("button_click", -10.0, 0.7)
	await customer.enter_shop(ENTRANCE, COUNTER_SPOT)
	if _floor != "loja":
		AudioManager.play_sfx("coin_drop", -6.0, 1.4)
		_toast_message("Um cliente chegou ao balcão! Desça para atender.", 2.0)
	_update_hint()
	await trade_panel.closed
	var result: Dictionary = GameState.today["customers"].back()
	var profile: Dictionary = GameData.CUSTOMERS[customer_id]
	customer.say(profile["happy"] if result.get("success", false) else profile["sad"], 1.6)
	await get_tree().create_timer(0.8).timeout
	await customer.leave_shop(ENTRANCE)
	_update_hint()


func _pick_customer() -> String:
	var pool: Array = GameData.DISTRICTS[GameState.district]["customers"].filter(
		func(id: String) -> bool: return int(GameData.CUSTOMERS[id]["min_level"]) <= GameState.level
	)
	if pool.size() > 1:
		pool.erase(_last_customer_id)
	return pool[randi() % pool.size()]


func _apply_district_look() -> void:
	var tint: Color = GameData.DISTRICTS[GameState.district]["tint"]
	create_tween().tween_property(_tint, "color", tint, 0.6)


# ============================================================== Interação
func _on_player_interact() -> void:
	if _trade_open or _changing_floor:
		return
	if _floor == "loja" and customer.waiting and customer.is_player_near():
		_open_trade_panel()
		return
	var door := _door_under_player()
	if door != null:
		_use_door(door)


func _open_trade_panel() -> void:
	_trade_open = true
	customer.hide_bubble()
	player.set_movement_enabled(false)
	customer.set_interaction_hint_visible(false)
	customer.play_interact()
	trade_panel.open(_current_order, customer.profile_id)
	create_tween().tween_property(camera, "offset", CAMERA_PANEL_OFFSET, 0.35).set_trans(Tween.TRANS_SINE)
	_update_hint()


func _on_trade_resolved(result: Dictionary) -> void:
	customer.waiting = false
	GameState.record_customer(result)
	if result.get("success", false):
		GameState.add_money(float(result["revenue"]))
		GameState.add_xp(int(result["xp"]))
		var origin: Vector2 = _money_label.global_position + Vector2(_money_label.size.x * 0.5, _money_label.size.y)
		effects.play_coin_burst(origin, 12)
		player.play_sell_action()
	else:
		player.play_interact()
	_refresh_hud()


func _on_trade_closed() -> void:
	_trade_open = false
	player.set_movement_enabled(true)
	create_tween().tween_property(camera, "offset", Vector2.ZERO, 0.35).set_trans(Tween.TRANS_SINE)
	_update_hint()


func _on_money_changed(previous: float, current: float) -> void:
	if _money_label == null:
		return
	_refresh_hud()
	effects.pulse_label(_money_label)
	# Começa abaixo da barra superior para não cobrir o HUD.
	var origin := _money_label.global_position + Vector2(0, _money_label.size.y + 70)
	if current > previous:
		effects.play_floating_text(origin, "+" + GameData.money(current - previous), UITheme.GOLD)
	elif current < previous:
		effects.play_floating_text(origin, "−" + GameData.money(previous - current), Color(0.95, 0.35, 0.3))


func _on_level_up(new_level: int) -> void:
	AudioManager.play_sfx("level_up")
	effects.play_level_up_burst(_level_label.global_position + _level_label.size * 0.5)
	effects.pulse_label(_level_label, 1.2, 0.5)
	var unlocked := ""
	for district_id in GameData.DISTRICT_ORDER:
		if int(GameData.DISTRICTS[district_id]["unlock_level"]) == new_level:
			unlocked = GameData.DISTRICTS[district_id]["name"]
	_toast_message("Sua loja agora é: %s!%s" % [GameData.level_name(new_level), ("\nNovo bairro: " + unlocked) if unlocked != "" else ""], 3.5)
	_pending_story.append("level_%d" % new_level)


# ==================================================================== HUD
func _build_hud() -> void:
	var bar := PanelContainer.new()
	bar.theme_type_variation = "WoodPanel"
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 12
	bar.offset_right = -12
	bar.offset_top = 10
	bar.offset_bottom = 58
	ui.add_child(bar)
	ui.move_child(bar, 0)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	bar.add_child(row)

	_day_label = _hud_label(row, 20, true)
	_district_label = _hud_label(row, 18)
	_money_label = _hud_label(row, 20, true)
	_money_label.add_theme_color_override("font_color", UITheme.GOLD)

	var level_box := HBoxContainer.new()
	level_box.add_theme_constant_override("separation", 8)
	row.add_child(level_box)
	_level_label = _hud_label(level_box, 18)
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(110, 14)
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_xp_bar.show_percentage = false
	level_box.add_child(_xp_bar)

	_queue_label = _hud_label(row, 18)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	_sound_button = Button.new()
	_sound_button.theme_type_variation = "SecondaryButton"
	_sound_button.focus_mode = Control.FOCUS_NONE
	_sound_button.pressed.connect(func() -> void:
		GameState.toggle_mute()
		_refresh_hud()
	)
	row.add_child(_sound_button)
	var menu := Button.new()
	menu.text = "Menu"
	menu.theme_type_variation = "SecondaryButton"
	menu.focus_mode = Control.FOCUS_NONE
	menu.pressed.connect(_on_back_menu)
	row.add_child(menu)

	var hint_panel := PanelContainer.new()
	hint_panel.theme_type_variation = "WoodPanel"
	hint_panel.anchor_top = 1.0
	hint_panel.anchor_bottom = 1.0
	hint_panel.offset_left = 12
	hint_panel.offset_top = -52
	hint_panel.offset_bottom = -12
	hint_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	ui.add_child(hint_panel)
	ui.move_child(hint_panel, 1)
	_hint_label = _hud_label(hint_panel, 17)

	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_top = 80
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.add_theme_font_override("font", UITheme.font(true))
	_toast.add_theme_font_size_override("font_size", 26)
	_toast.add_theme_color_override("font_color", UITheme.CREAM)
	_toast.add_theme_color_override("font_outline_color", UITheme.WOOD_DARK)
	_toast.add_theme_constant_override("outline_size", 10)
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_toast)


func _hud_label(parent: Control, font_size: int, bold: bool = false) -> Label:
	var label := Label.new()
	label.theme_type_variation = "LightLabel"
	label.add_theme_font_size_override("font_size", font_size)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if bold:
		label.add_theme_font_override("font", UITheme.font(true))
	parent.add_child(label)
	return label


func _build_overlays() -> void:
	_fade = ColorRect.new()
	_fade.color = Color(0.08, 0.04, 0.02, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_fade)
	_morning = MorningPanel.new()
	ui.add_child(_morning)
	_summary = DaySummaryPanel.new()
	ui.add_child(_summary)
	_dialogue = DialogueBox.new()
	ui.add_child(_dialogue)
	# Efeitos sempre por cima de tudo
	ui.move_child(effects, ui.get_child_count() - 1)
	# Controles dentro de CanvasLayer não herdam o tema da janela: aplica aqui.
	for child in ui.get_children():
		if child is Control:
			child.theme = GameState.ui_theme


func _refresh_hud() -> void:
	if _day_label == null:
		return
	var total := _day_total if _day_total > 0 else GameState.customers_per_day()
	var period := "Manhã"
	if _customers_served > 0:
		period = "Tarde" if _customers_served < total else "Entardecer"
	_day_label.text = "Dia %d · %s" % [GameState.day, period]
	_district_label.text = "%s · %s" % [GameData.DISTRICTS[GameState.district]["name"], FLOOR_NAMES[_floor]]
	_money_label.text = "● %s" % GameData.money(GameState.money)
	_money_label.add_theme_color_override("font_color", UITheme.GOLD if GameState.money >= 0 else Color(1.0, 0.45, 0.4))
	_level_label.text = GameData.level_name(GameState.level)
	var next_xp := GameState.xp_for_next_level()
	if next_xp < 0:
		_xp_bar.max_value = 1
		_xp_bar.value = 1
		_xp_bar.tooltip_text = "XP %d — nível máximo" % GameState.xp
	else:
		var floor_xp := int(GameData.LEVEL_XP[GameState.level])
		_xp_bar.max_value = next_xp - floor_xp
		_xp_bar.value = GameState.xp - floor_xp
		_xp_bar.tooltip_text = "XP %d de %d para %s" % [GameState.xp, next_xp, GameData.level_name(GameState.level + 1)]
	_queue_label.text = "Clientes: %d/%d" % [_customers_served, total]
	_sound_button.text = "Som: não" if GameState.muted else "Som: sim"
	_update_hint()


func _update_hint() -> void:
	if _hint_label == null:
		return
	if _trade_open:
		_hint_label.text = "Preencha o pedido no painel ao lado  ·  Enter também vende"
	elif customer.waiting and customer.is_player_near():
		_hint_label.text = "Pressione [E] para atender %s" % GameData.CUSTOMERS[customer.profile_id]["name"]
	elif customer.waiting and _floor != "loja":
		_hint_label.text = "Um cliente está no balcão! Desça pela escada ou pela porta  ·  E: usar porta"
	elif customer.waiting:
		_hint_label.text = "Um cliente chegou! Vá até o balcão  ·  WASD/setas: andar  ·  Shift: correr"
	elif _floor == "oficina":
		_hint_label.text = "Oficina do mestre vidreiro  ·  E na escada ou na porta para descer"
	else:
		_hint_label.text = "WASD/setas: andar  ·  Shift: correr  ·  E: atender / usar portas"
	customer.set_interaction_hint_visible(customer.waiting and customer.is_player_near() and not _trade_open)


func _toast_message(text: String, duration: float = 2.2) -> void:
	_toast.text = text
	_toast.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_toast, "modulate:a", 1.0, 0.25)
	tween.tween_interval(duration)
	tween.tween_property(_toast, "modulate:a", 0.0, 0.4)


func _on_back_menu() -> void:
	AudioManager.play_sfx("button_click")
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
