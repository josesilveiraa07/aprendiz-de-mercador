extends Control
class_name MorningPanel
## Manhã: escolha do bairro e compra de mercadoria no fornecedor.
## Implementa a etapa "Comprar/Gerenciar" do Core Loop do GDD, que no
## Vertical Slice existia só como desconto automático do custo na venda.

signal done

var _cart: Dictionary = {}
var _rows: Dictionary = {}
var _title: Label
var _subtitle: RichTextLabel
var _district_row: HBoxContainer
var _district_desc: Label
var _table: GridContainer
var _summary: RichTextLabel
var _open_button: Button


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.04, 0.02, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(860, 0)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	_title = Label.new()
	_title.theme_type_variation = "TitleLabel"
	_title.add_theme_font_size_override("font_size", 30)
	vbox.add_child(_title)

	_subtitle = RichTextLabel.new()
	_subtitle.bbcode_enabled = true
	_subtitle.fit_content = true
	_subtitle.scroll_active = false
	vbox.add_child(_subtitle)

	var district_title := Label.new()
	district_title.text = "ONDE ABRIR A LOJA HOJE?"
	district_title.theme_type_variation = "SmallLabel"
	vbox.add_child(district_title)
	_district_row = HBoxContainer.new()
	_district_row.add_theme_constant_override("separation", 8)
	vbox.add_child(_district_row)
	_district_desc = Label.new()
	_district_desc.theme_type_variation = "SmallLabel"
	vbox.add_child(_district_desc)

	var card := PanelContainer.new()
	card.theme_type_variation = "CardPanel"
	vbox.add_child(card)
	_table = GridContainer.new()
	_table.columns = 6
	_table.add_theme_constant_override("h_separation", 22)
	_table.add_theme_constant_override("v_separation", 6)
	card.add_child(_table)

	_summary = RichTextLabel.new()
	_summary.bbcode_enabled = true
	_summary.fit_content = true
	_summary.scroll_active = false
	_summary.add_theme_font_size_override("normal_font_size", 20)
	_summary.add_theme_font_size_override("bold_font_size", 20)
	vbox.add_child(_summary)

	_open_button = Button.new()
	_open_button.text = "Comprar e abrir a loja  ▸"
	_open_button.custom_minimum_size = Vector2(0, 48)
	_open_button.pressed.connect(_on_open_pressed)
	vbox.add_child(_open_button)


func show_morning() -> void:
	_cart.clear()
	_title.text = "Dia %d · Manhã no fornecedor" % GameState.day
	var expected := GameState.customers_per_day()
	_subtitle.text = "[color=#%s][b]%s:[/b] Hoje devem vir uns [b]%d clientes[/b]. Cada um leva de %s unidades. Compre o que acha que vai vender — mercadoria parada é dinheiro parado![/color]" % [
		UITheme.SKY.to_html(false), GameData.GRANDMA_NAME, expected, _qty_range_text()
	]
	_build_districts()
	_build_table()
	_refresh()
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	await done


func _qty_range_text() -> String:
	var r: Vector2i = ChallengeGenerator.QTY_BY_LEVEL.get(GameState.level, Vector2i(1, 4))
	return "%d a %d" % [r.x, r.y]


func _build_districts() -> void:
	for child in _district_row.get_children():
		child.queue_free()
	for district_id in GameData.DISTRICT_ORDER:
		var info: Dictionary = GameData.DISTRICTS[district_id]
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 44)
		var unlocked: bool = int(info["unlock_level"]) <= GameState.level
		if not unlocked:
			button.text = "%s (nível %d)" % [info["name"], info["unlock_level"]]
			button.disabled = true
		else:
			button.text = info["name"]
			button.theme_type_variation = "" if district_id == GameState.district else "SecondaryButton"
			button.pressed.connect(func() -> void:
				AudioManager.play_sfx("button_click")
				GameState.district = district_id
				_cart.clear()
				_build_districts()
				_build_table()
				_refresh()
			)
		_district_row.add_child(button)
	_district_desc.text = GameData.DISTRICTS[GameState.district]["description"]


func _build_table() -> void:
	for child in _table.get_children():
		child.queue_free()
	_rows.clear()
	for header in ["Produto", "Compra (un.)", "Venda (un.)", "Estoque", "Comprar", "Subtotal"]:
		var h := Label.new()
		h.text = header
		h.theme_type_variation = "SmallLabel"
		_table.add_child(h)

	var products := GameData.district_products(GameState.district)
	for product in products:
		var data: Dictionary = products[product]
		_table.add_child(_cell(product, true))
		_table.add_child(_cell(GameData.money(data["buy"])))
		_table.add_child(_cell(GameData.money(data["base"])))
		_table.add_child(_cell(str(GameState.stock_of(product))))

		var stepper := HBoxContainer.new()
		stepper.add_theme_constant_override("separation", 4)
		var minus := Button.new()
		minus.text = "−"
		minus.theme_type_variation = "SecondaryButton"
		minus.custom_minimum_size = Vector2(36, 34)
		var qty := Label.new()
		qty.custom_minimum_size = Vector2(34, 0)
		qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qty.add_theme_font_override("font", UITheme.font(true))
		var plus := Button.new()
		plus.text = "+"
		plus.custom_minimum_size = Vector2(36, 34)
		minus.pressed.connect(func() -> void: _change(product, -1))
		plus.pressed.connect(func() -> void: _change(product, 1))
		stepper.add_child(minus)
		stepper.add_child(qty)
		stepper.add_child(plus)
		_table.add_child(stepper)
		var subtotal := _cell("0,00")
		_table.add_child(subtotal)
		_rows[product] = {"qty": qty, "subtotal": subtotal, "buy": float(data["buy"])}


func _cell(text: String, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if bold:
		label.add_theme_font_override("font", UITheme.font(true))
	return label


func _change(product: String, delta: int) -> void:
	var current := int(_cart.get(product, 0))
	var next := maxi(0, current + delta)
	if delta > 0 and _cart_total() + float(_rows[product]["buy"]) > GameState.money + 0.001:
		AudioManager.play_sfx("error")
		return
	_cart[product] = next
	AudioManager.play_sfx("coin_drop", -16.0, 1.3 if delta > 0 else 0.9)
	_refresh()


func _cart_total() -> float:
	var total := 0.0
	for product in _cart:
		total += float(_rows[product]["buy"]) * int(_cart[product])
	return total


func _refresh() -> void:
	for product in _rows:
		var qty := int(_cart.get(product, 0))
		_rows[product]["qty"].text = str(qty)
		_rows[product]["subtotal"].text = GameData.money(float(_rows[product]["buy"]) * qty)
	var total := _cart_total()
	var after := GameState.money - total
	_summary.text = "Caixa: [b]%s[/b]   −   Compra: [b]%s[/b]   =   Sobra: [b][color=#%s]%s[/color][/b]" % [
		GameData.money(GameState.money), GameData.money(total),
		(UITheme.SUCCESS if after >= 0 else UITheme.ERROR).to_html(false), GameData.money(after)
	]
	_open_button.text = "Comprar e abrir a loja  ▸" if total > 0 else "Abrir a loja sem comprar  ▸"


func _on_open_pressed() -> void:
	AudioManager.play_sfx("button_click")
	var products := GameData.district_products(GameState.district)
	for product in _cart:
		if int(_cart[product]) > 0:
			GameState.buy_stock(product, int(_cart[product]), float(products[product]["buy"]))
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
	visible = false
	done.emit()
