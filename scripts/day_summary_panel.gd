extends Control
class_name DaySummaryPanel
## Entardecer: resumo do dia (receita, custo, lucro e desempenho).

signal done

var _title: Label
var _list: GridContainer
var _totals: RichTextLabel
var _xp_bar: ProgressBar
var _xp_label: Label
var _button: Button


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.05, 0.03, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	_title = Label.new()
	_title.theme_type_variation = "TitleLabel"
	_title.add_theme_font_size_override("font_size", 30)
	vbox.add_child(_title)

	var card := PanelContainer.new()
	card.theme_type_variation = "CardPanel"
	vbox.add_child(card)
	_list = GridContainer.new()
	_list.columns = 4
	_list.add_theme_constant_override("h_separation", 26)
	_list.add_theme_constant_override("v_separation", 4)
	card.add_child(_list)

	_totals = RichTextLabel.new()
	_totals.bbcode_enabled = true
	_totals.fit_content = true
	_totals.scroll_active = false
	_totals.add_theme_font_size_override("normal_font_size", 20)
	_totals.add_theme_font_size_override("bold_font_size", 20)
	vbox.add_child(_totals)

	_xp_label = Label.new()
	vbox.add_child(_xp_label)
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(0, 20)
	_xp_bar.show_percentage = false
	vbox.add_child(_xp_bar)

	_button = Button.new()
	_button.text = "Fechar a loja e descansar  ▸"
	_button.custom_minimum_size = Vector2(0, 48)
	_button.pressed.connect(func() -> void:
		AudioManager.play_sfx("button_click")
		visible = false
		done.emit()
	)
	vbox.add_child(_button)


func show_summary() -> void:
	var today: Dictionary = GameState.today
	_title.text = "Dia %d · Entardecer" % GameState.day

	for child in _list.get_children():
		child.queue_free()
	for header in ["Cliente", "Conteúdo", "Resultado", "Recebido"]:
		var h := Label.new()
		h.text = header
		h.theme_type_variation = "SmallLabel"
		_list.add_child(h)

	var sales := 0
	for result in today["customers"]:
		_list.add_child(_cell(result["customer"]))
		_list.add_child(_cell(result["topic"]))
		var status := Label.new()
		if result.get("success", false):
			status.text = "✔ Venda (%d/3)" % int(result.get("score", 0))
			status.add_theme_color_override("font_color", UITheme.SUCCESS)
			sales += 1
		elif result.get("wise_refusal", false):
			status.text = "◆ Sem estoque"
			status.add_theme_color_override("font_color", UITheme.SKY)
		elif result.get("refused", false):
			status.text = "✘ Recusado"
			status.add_theme_color_override("font_color", UITheme.ERROR)
		else:
			status.text = "✘ Perdida"
			status.add_theme_color_override("font_color", UITheme.ERROR)
		_list.add_child(status)
		_list.add_child(_cell(GameData.money(float(result.get("revenue", 0.0)))))

	var revenue := float(today["revenue"])
	var cogs := float(today["cost_of_goods"])
	var profit := revenue - cogs
	var color := (UITheme.SUCCESS if profit >= 0 else UITheme.ERROR).to_html(false)
	_totals.text = "Vendas: [b]%d de %d[/b]\n" % [sales, today["customers"].size()]
	_totals.text += "Receita: [b]%s[/b]   −   Custo do que foi vendido: [b]%s[/b]   =   Lucro do dia: [b][color=#%s]%s[/color][/b]\n" % [
		GameData.money(revenue), GameData.money(cogs), color, GameData.money(profit)
	]
	_totals.text += "Gasto no fornecedor hoje: %s   ·   Caixa agora: [b]%s[/b]" % [
		GameData.money(float(today["purchases"])), GameData.money(GameState.money)
	]

	var next_xp := GameState.xp_for_next_level()
	if next_xp < 0:
		_xp_label.text = "%s · XP %d (nível máximo!)  ·  +%d XP hoje" % [GameData.level_name(GameState.level), GameState.xp, today["xp_gained"]]
		_xp_bar.max_value = 1
		_xp_bar.value = 1
	else:
		var current_floor := int(GameData.LEVEL_XP[GameState.level])
		_xp_label.text = "%s · XP %d/%d para %s  ·  +%d XP hoje" % [
			GameData.level_name(GameState.level), GameState.xp, next_xp,
			GameData.level_name(GameState.level + 1), today["xp_gained"]
		]
		_xp_bar.max_value = next_xp - current_floor
		_xp_bar.value = GameState.xp - current_floor

	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)
	AudioManager.play_sfx("new_day", -6.0, 0.85)
	_button.grab_focus()
	await done


func _cell(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label
