extends Control
## Menu principal: Continuar / Novo jogo / Relatório do professor / Som / Sair.

const BACKGROUND := "res://assets/art/menu_background.png"

var _title: Label
var _continue_button: Button
var _sound_button: Button
var _report: ReportPanel
var _confirm: ConfirmationDialog


func _ready() -> void:
	_build()
	_animate_title()


func _build() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if ResourceLoader.exists(BACKGROUND):
		bg.texture = load(BACKGROUND)
	add_child(bg)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.1, 0.05, 0.02, 0.45)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	margin.offset_right = 520
	margin.add_theme_constant_override("margin_left", 64)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	add_child(margin)

	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	margin.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	_title = Label.new()
	_title.text = "Aprendiz de\nMercador"
	_title.theme_type_variation = "TitleLabel"
	_title.add_theme_font_size_override("font_size", 52)
	_title.add_theme_color_override("font_color", UITheme.EMBER_DARK)
	vbox.add_child(_title)

	var subtitle := Label.new()
	subtitle.text = "Um RPG econômico de matemática financeira\nnas ruas de Vilaforte."
	subtitle.theme_type_variation = "SmallLabel"
	subtitle.add_theme_font_size_override("font_size", 18)
	vbox.add_child(subtitle)

	vbox.add_child(HSeparator.new())

	_continue_button = _add_button(vbox, "Continuar", "", _on_continue)
	_continue_button.visible = GameState.has_save()
	if _continue_button.visible and GameState.load_game():
		_continue_button.text = "Continuar  ·  Dia %d, %s" % [GameState.day, GameData.level_name(GameState.level)]
	_add_button(vbox, "Novo jogo", "" if not _continue_button.visible else "SecondaryButton", _on_new_game)
	_add_button(vbox, "Relatório do professor", "SecondaryButton", _on_report)
	_sound_button = _add_button(vbox, "", "SecondaryButton", _on_toggle_sound)
	_update_sound_text()
	_add_button(vbox, "Sair", "SecondaryButton", func() -> void: get_tree().quit())

	var credits := Label.new()
	credits.text = "PAC Extensionista · Engenharia de Software · Católica SC"
	credits.theme_type_variation = "SmallLabel"
	credits.add_theme_font_size_override("font_size", 13)
	vbox.add_child(credits)

	_report = ReportPanel.new()
	add_child(_report)

	_confirm = ConfirmationDialog.new()
	_confirm.title = "Novo jogo"
	_confirm.dialog_text = "Começar do zero? O progresso salvo será apagado\n(o relatório da sessão continua disponível)."
	_confirm.ok_button_text = "Começar do zero"
	_confirm.cancel_button_text = "Cancelar"
	_confirm.confirmed.connect(_start_new_game)
	add_child(_confirm)

	(_continue_button if _continue_button.visible else vbox.get_child(4)).grab_focus()


func _add_button(parent: Control, text: String, variation: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = variation
	button.custom_minimum_size = Vector2(360, 48)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(func() -> void: AudioManager.play_sfx("button_click"))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _animate_title() -> void:
	_title.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_title, "modulate:a", 1.0, 0.7).set_ease(Tween.EASE_OUT)


func _on_continue() -> void:
	GameState.load_game()
	get_tree().change_scene_to_file("res://scenes/market.tscn")


func _on_new_game() -> void:
	if GameState.has_save():
		_confirm.popup_centered()
	else:
		_start_new_game()


func _start_new_game() -> void:
	GameState.delete_save()
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/market.tscn")


func _on_report() -> void:
	_report.show_report()


func _on_toggle_sound() -> void:
	GameState.toggle_mute()
	_update_sound_text()


func _update_sound_text() -> void:
	_sound_button.text = "Som: desligado" if GameState.muted else "Som: ligado"
