extends Control
class_name DialogueBox
## Caixa de diálogo com efeito de máquina de escrever, usada na narrativa
## da avó de Marco. Avança com E, Espaço, Enter ou clique.

signal finished

const CHARS_PER_SECOND := 45.0

var _lines: Array = []
var _index := 0
var _visible_chars := 0.0
var _typing := false

var _panel: PanelContainer
var _portrait_holder: CenterContainer
var _name_label: Label
var _text: RichTextLabel
var _continue: Label


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.04, 0.02, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -470
	_panel.offset_right = 470
	_panel.offset_top = -210
	_panel.offset_bottom = -24
	add_child(_panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	_panel.add_child(hbox)

	var portrait_card := PanelContainer.new()
	portrait_card.theme_type_variation = "CardPanel"
	portrait_card.custom_minimum_size = Vector2(140, 140)
	hbox.add_child(portrait_card)
	_portrait_holder = CenterContainer.new()
	portrait_card.add_child(_portrait_holder)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	hbox.add_child(vbox)

	_name_label = Label.new()
	_name_label.theme_type_variation = "NameLabel"
	_name_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_name_label)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 21)
	_text.add_theme_font_size_override("bold_font_size", 21)
	vbox.add_child(_text)

	_continue = Label.new()
	_continue.theme_type_variation = "SmallLabel"
	_continue.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue.text = "E / Espaço / clique para continuar ▸"
	vbox.add_child(_continue)


func play(lines: Array) -> void:
	_lines = lines
	_index = 0
	visible = true
	_show_line()
	await finished


func _show_line() -> void:
	var line: Array = _lines[_index]
	var speaker: String = line[0]
	_name_label.text = speaker
	_text.text = str(line[1])
	_text.visible_characters = 0
	_visible_chars = 0.0
	_typing = true
	_continue.modulate.a = 0.0
	for child in _portrait_holder.get_children():
		child.queue_free()
	_portrait_holder.add_child(_portrait_for(speaker))
	AudioManager.play_sfx("button_click", -18.0, 1.4)


func _portrait_for(speaker: String) -> TextureRect:
	var rect: TextureRect
	if speaker == GameData.GRANDMA_NAME:
		var atlas := AtlasTexture.new()
		atlas.atlas = load("res://assets/craftpix/characters/Seller.png")
		atlas.region = Rect2(0, 0, 32, 32)
		rect = TextureRect.new()
		rect.texture = atlas
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# Cabelo grisalho para a vó, reaproveitando o sprite da vendedora.
		rect.material = CustomerNPC.make_material({"hair": Vector3(0.0, 0.05, 1.9)})
	else:
		rect = CustomerNPC.make_portrait({})
	rect.custom_minimum_size = Vector2(128, 128)
	return rect


func _process(delta: float) -> void:
	if not visible or not _typing:
		return
	_visible_chars += delta * CHARS_PER_SECOND
	_text.visible_characters = int(_visible_chars)
	if _text.visible_characters >= _text.get_total_character_count():
		_finish_typing()


func _finish_typing() -> void:
	_typing = false
	_text.visible_characters = -1
	_continue.modulate.a = 1.0


func _advance() -> void:
	if _typing:
		_finish_typing()
		return
	_index += 1
	if _index >= _lines.size():
		visible = false
		finished.emit()
		return
	_show_line()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		_advance()
		get_viewport().set_input_as_handled()
