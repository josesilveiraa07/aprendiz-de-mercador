extends Control
## Painel de negociação no balcão.
## Regras do GDD mantidas: a venda é avaliada por 3 critérios (Pedido, Preço e
## Cálculo). O número mínimo de acertos agora depende da personalidade do cliente.

signal resolved(result: Dictionary)
signal closed

var order: Dictionary = {}
var customer_id := ""
var customer: Dictionary = {}

var _retries_left := 0
var _time_left := 0.0
var _opened_at := 0
var _used_hint := false
var _done := false
var _last_result: Dictionary = {}

# Nós montados em código
var _panel: PanelContainer
var _portrait_holder: CenterContainer
var _name_label: Label
var _trait_label: Label
var _trait_desc: Label
var _speech: RichTextLabel
var _timer_bar: ProgressBar
var _price_table: GridContainer
var _question: RichTextLabel
var _challenge_title: Label
var _hint_text: RichTextLabel
var _form: VBoxContainer
var _product_option: OptionButton
var _qty_spin: SpinBox
var _discount_spin: SpinBox
var _answer_input: LineEdit
var _message: RichTextLabel
var _hint_button: Button
var _refuse_button: Button
var _sell_button: Button
var _result_box: PanelContainer
var _result_text: RichTextLabel
var _continue_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	visible = false


func get_effects() -> CanvasLayer:
	return get_parent().get_node_or_null("EffectsLayer")


# ====================================================================== UI
func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -548
	_panel.offset_right = -12
	_panel.offset_top = 66
	_panel.offset_bottom = -10
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	scroll.add_child(root)

	# --- Cabeçalho do cliente
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	var portrait_card := PanelContainer.new()
	portrait_card.theme_type_variation = "CardPanel"
	portrait_card.custom_minimum_size = Vector2(80, 80)
	header.add_child(portrait_card)
	_portrait_holder = CenterContainer.new()
	portrait_card.add_child(_portrait_holder)

	var who := VBoxContainer.new()
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.add_theme_constant_override("separation", 2)
	header.add_child(who)
	_name_label = Label.new()
	_name_label.theme_type_variation = "NameLabel"
	_name_label.add_theme_font_size_override("font_size", 22)
	who.add_child(_name_label)
	_trait_label = Label.new()
	_trait_label.add_theme_color_override("font_color", UITheme.EMBER_DARK)
	_trait_label.add_theme_font_override("font", UITheme.font(true))
	who.add_child(_trait_label)
	_trait_desc = Label.new()
	_trait_desc.theme_type_variation = "SmallLabel"
	_trait_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	who.add_child(_trait_desc)
	_timer_bar = ProgressBar.new()
	_timer_bar.custom_minimum_size = Vector2(0, 16)
	_timer_bar.show_percentage = false
	who.add_child(_timer_bar)

	# --- Fala / pedido
	var speech_card := _card(root)
	_speech = _rich(speech_card, 19)

	# --- Tabela de preços do bairro (compacta: 2 colunas)
	var table_card := _card(root)
	var table_box := VBoxContainer.new()
	table_box.add_theme_constant_override("separation", 2)
	table_card.add_child(table_box)
	table_box.add_child(_small_title("Tabela de preços (por unidade) · estoque"))
	_price_table = GridContainer.new()
	_price_table.columns = 2
	_price_table.add_theme_constant_override("h_separation", 24)
	_price_table.add_theme_constant_override("v_separation", 0)
	table_box.add_child(_price_table)

	# --- Desafio
	var challenge_card := _card(root)
	var challenge_box := VBoxContainer.new()
	challenge_box.add_theme_constant_override("separation", 2)
	challenge_card.add_child(challenge_box)
	_challenge_title = _small_title("Desafio do balcão")
	challenge_box.add_child(_challenge_title)
	_question = _rich(challenge_box, 19)
	_hint_text = _rich(challenge_box, 16)
	_hint_text.visible = false

	# --- Formulário
	_form = VBoxContainer.new()
	_form.add_theme_constant_override("separation", 6)
	root.add_child(_form)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 10)
	_form.add_child(row1)
	row1.add_child(_label("Produto"))
	_product_option = OptionButton.new()
	_product_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(_product_option)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 10)
	_form.add_child(row2)
	row2.add_child(_label("Qtd."))
	_qty_spin = SpinBox.new()
	_qty_spin.min_value = 1
	_qty_spin.max_value = 30
	_qty_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(_qty_spin)
	row2.add_child(_label("Desconto"))
	_discount_spin = SpinBox.new()
	_discount_spin.min_value = 0
	_discount_spin.max_value = 90
	_discount_spin.suffix = "%"
	_discount_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(_discount_spin)

	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 10)
	_form.add_child(row3)
	row3.add_child(_label("Resposta"))
	_answer_input = LineEdit.new()
	_answer_input.placeholder_text = "ex.: 12,50  ou  -3"
	_answer_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_answer_input.text_submitted.connect(func(_t: String) -> void: _on_sell_pressed())
	row3.add_child(_answer_input)

	_message = _rich(_form, 17)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	_form.add_child(buttons)
	_hint_button = _button(buttons, "Dica da vó", "HintButton", _on_hint_pressed)
	_refuse_button = _button(buttons, "Recusar", "SecondaryButton", _on_refuse_pressed)
	_sell_button = _button(buttons, "Vender", "", _on_sell_pressed)
	_sell_button.size_flags_stretch_ratio = 1.4

	# --- Resultado
	_result_box = PanelContainer.new()
	_result_box.theme_type_variation = "CardPanel"
	_result_box.visible = false
	root.add_child(_result_box)
	var result_vbox := VBoxContainer.new()
	result_vbox.add_theme_constant_override("separation", 8)
	_result_box.add_child(result_vbox)
	_result_text = _rich(result_vbox, 18)
	_continue_button = _button(result_vbox, "Continuar  ▸", "", _on_continue_pressed)


func _card(parent: Control) -> PanelContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = "CardPanel"
	parent.add_child(card)
	return card


func _rich(parent: Control, font_size: int) -> RichTextLabel:
	var rich := RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.fit_content = true
	rich.scroll_active = false
	rich.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rich.add_theme_font_size_override("normal_font_size", font_size)
	rich.add_theme_font_size_override("bold_font_size", font_size)
	parent.add_child(rich)
	return rich


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", UITheme.font(true))
	return label


func _small_title(text: String) -> Label:
	var label := Label.new()
	label.text = text.to_upper()
	label.theme_type_variation = "SmallLabel"
	label.add_theme_font_override("font", UITheme.font(true))
	return label


func _button(parent: Control, text: String, variation: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = variation
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 40)
	button.pressed.connect(func() -> void: AudioManager.play_sfx("button_click"))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


# ================================================================ Fluxo
func open(new_order: Dictionary, new_customer_id: String) -> void:
	order = new_order
	customer_id = new_customer_id
	customer = GameData.CUSTOMERS[customer_id]
	_retries_left = int(customer.get("retries", 0))
	_time_left = float(customer.get("time_limit", 0))
	_used_hint = false
	_done = false
	_opened_at = Time.get_ticks_msec()

	for child in _portrait_holder.get_children():
		child.queue_free()
	var portrait := CustomerNPC.make_portrait(customer.get("colors", {}))
	portrait.custom_minimum_size = Vector2(72, 72)
	_portrait_holder.add_child(portrait)
	_name_label.text = customer["name"]
	_trait_label.text = "%s · precisa de %d/3 critérios" % [customer["trait"], customer["min_score"]]
	_trait_desc.text = customer["trait_desc"]
	_timer_bar.visible = _time_left > 0
	_timer_bar.max_value = maxf(_time_left, 1.0)
	_timer_bar.value = _time_left

	_speech.text = "[i]\"%s\"[/i]" % order["request"]
	if order["topic"] == "troco":
		_speech.append_text("\n[i]\"Vou pagar com uma moeda de [b]%s[/b].\"[/i]" % GameData.num(order["paid"]))
	_fill_price_table()
	_challenge_title.text = ("Desafio do balcão · " + str(order["topic_name"])).to_upper()
	_question.text = "[b]%s[/b]" % order["question"]
	_hint_text.visible = false
	_hint_text.text = ""

	_product_option.clear()
	for product in GameData.district_products(GameState.district):
		_product_option.add_item(product)
	_product_option.select(0)
	_qty_spin.value = 1
	_discount_spin.value = 0
	_answer_input.text = ""
	_message.text = ""
	_form.visible = true
	_hint_button.disabled = false
	_result_box.visible = false
	visible = true
	_panel.modulate.a = 0.0
	_panel.position.x += 40
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.25)
	tween.tween_property(_panel, "position:x", _panel.position.x - 40, 0.25).set_ease(Tween.EASE_OUT)
	_product_option.grab_focus()


func _fill_price_table() -> void:
	for child in _price_table.get_children():
		child.queue_free()
	var products := GameData.district_products(GameState.district)
	for product in products:
		var stock := GameState.stock_of(product)
		var cell := Label.new()
		cell.text = "%s  %s  ·  %d un." % [product, GameData.money(products[product]["base"]), stock]
		cell.add_theme_font_size_override("font_size", 16)
		if product == order["product"]:
			cell.add_theme_font_override("font", UITheme.font(true))
		if stock == 0:
			cell.add_theme_color_override("font_color", UITheme.ERROR)
		_price_table.add_child(cell)


func _process(delta: float) -> void:
	if not visible or _done or _time_left <= 0.0:
		return
	_time_left -= delta
	_timer_bar.value = _time_left
	if _time_left <= 10.0:
		_timer_bar.modulate = Color(1.0, 0.55, 0.5)
	else:
		_timer_bar.modulate = Color.WHITE
	if _time_left <= 0.0:
		_finish_fail("%s se cansou de esperar e foi embora." % customer["name"], false, false, true)


func _on_hint_pressed() -> void:
	if _done or order.is_empty():
		return
	_used_hint = true
	_hint_button.disabled = true
	_hint_text.visible = true
	_hint_text.text = "[color=#%s][b]Vó Celeste:[/b] %s[/color]" % [UITheme.SKY.to_html(false), order["hint"]]


func _on_refuse_pressed() -> void:
	if _done or order.is_empty():
		return
	var has_stock := GameState.stock_of(order["product"]) >= int(order["qty"])
	var text := "Você recusou o pedido."
	if not has_stock:
		text = "Sem estoque suficiente de %s. Recusar foi a decisão certa — compre mais amanhã cedo!" % order["product"]
	AudioManager.play_sfx("refuse")
	var effects := get_effects()
	if effects:
		effects.shake_control(_panel, 5.0)
	_finish_fail(text, true, not has_stock, true)


func _on_sell_pressed() -> void:
	if _done or order.is_empty():
		return
	var selected: String = _product_option.get_item_text(_product_option.selected)
	var qty := int(_qty_spin.value)
	var discount := float(_discount_spin.value)
	var answer := GameData.parse_answer(_answer_input.text)

	if is_nan(answer):
		_error("Digite a resposta do desafio (só números; use vírgula para centavos e − para negativo).")
		return
	if GameState.stock_of(selected) < qty:
		_error("Você só tem %d de %s no estoque. Ajuste a quantidade ou recuse o pedido." % [GameState.stock_of(selected), selected])
		return

	var product_data: Dictionary = GameData.district_products(GameState.district)[selected]
	var unit_charged := snappedf(float(product_data["base"]) * (1.0 - discount / 100.0), 0.01)
	var charged := snappedf(unit_charged * qty, 0.01)
	var cost := snappedf(float(product_data["buy"]) * qty, 0.01)

	var pedido_ok: bool = selected == order["product"] and qty == int(order["qty"])
	var preco_ok: bool = absf(charged - float(order["total"])) <= 0.011
	var calculo_ok: bool = absf(answer - float(order["answer"])) <= 0.011
	var score := int(pedido_ok) + int(preco_ok) + int(calculo_ok)
	var min_score := int(customer.get("min_score", 2))
	var success := score >= min_score

	GameState.record_attempt({
		"cliente": customer["name"],
		"perfil": customer["trait"],
		"topico": order["topic_name"],
		"pergunta": "%s %s" % [order["request"], order["question"]],
		"resposta_aluno": _answer_input.text.strip_edges(),
		"resposta_correta": GameData.money(order["answer"]),
		"calculo_ok": calculo_ok,
		"pedido_ok": pedido_ok,
		"preco_ok": preco_ok,
		"venda_aceita": success,
		"usou_dica": _used_hint,
		"tempo_segundos": int((Time.get_ticks_msec() - _opened_at) / 1000.0),
	})

	var checklist := _checklist(pedido_ok, preco_ok, calculo_ok)
	if success:
		_finish_success(score, charged, cost, selected, qty, checklist)
	elif _retries_left > 0:
		_retries_left -= 1
		AudioManager.play_sfx("error")
		var effects := get_effects()
		if effects:
			effects.shake_control(_panel, 5.0)
			effects.flash_panel(_panel, Color(0.9, 0.5, 0.2, 0.2))
		_message.text = "%s\n[b]%s:[/b] \"Hmm, confere de novo? Te dou mais uma chance.\"" % [checklist, customer["name"]]
	else:
		AudioManager.play_sfx("sale_fail")
		_finish_fail("%s\n\n[b]%s:[/b] \"%s\"" % [checklist, customer["name"], customer["sad"]], false)


func _checklist(pedido_ok: bool, preco_ok: bool, calculo_ok: bool) -> String:
	var ok := "[color=#%s]✔[/color]" % UITheme.SUCCESS.to_html(false)
	var bad := "[color=#%s]✘[/color]" % UITheme.ERROR.to_html(false)
	return "%s Pedido   %s Preço   %s Cálculo" % [
		ok if pedido_ok else bad, ok if preco_ok else bad, ok if calculo_ok else bad
	]


func _error(text: String) -> void:
	AudioManager.play_sfx("error")
	_message.text = "[color=#%s]%s[/color]" % [UITheme.ERROR.to_html(false), text]
	var effects := get_effects()
	if effects:
		effects.shake_control(_panel, 4.0)


func _finish_success(score: int, charged: float, cost: float, product: String, qty: int, checklist: String) -> void:
	_done = true
	GameState.remove_stock(product, qty)
	var xp_gain := 1 + int(customer.get("xp_bonus", 0))
	if score == 3 and not _used_hint:
		xp_gain += 1
	var profit := charged - cost

	AudioManager.play_sfx("sale_success")
	AudioManager.play_sfx("coin_drop", -4.0, randf_range(0.95, 1.05))
	var effects := get_effects()
	if effects:
		effects.flash_panel(_panel, Color(0.3, 0.8, 0.35, 0.22))

	var text := "[font_size=22][b][color=#%s]Venda fechada![/color][/b][/font_size]\n" % UITheme.SUCCESS.to_html(false)
	text += checklist + "\n"
	text += "Recebido: [b]%s[/b]   ·   Custo: %s   ·   Lucro: [b][color=#%s]%s[/color][/b]\n" % [
		GameData.money(charged), GameData.money(cost),
		(UITheme.SUCCESS if profit >= 0 else UITheme.ERROR).to_html(false), GameData.money(profit)
	]
	text += "XP: +%d%s\n" % [xp_gain, "  (bônus de conta perfeita!)" if score == 3 and not _used_hint else ""]
	text += "\n[b]%s:[/b] \"%s\"" % [customer["name"], customer["happy"]]
	if score < 3:
		text += "\n\n" + _solution_text()
	_show_result(text)

	_last_result = {
		"success": true,
		"customer": customer["name"],
		"topic": order["topic_name"],
		"revenue": charged,
		"cost": cost,
		"profit": profit,
		"xp": xp_gain,
		"score": score,
	}
	resolved.emit(_last_result)


func _finish_fail(text: String, refused: bool, wise_refusal: bool = false, log_it: bool = false) -> void:
	_done = true
	var body := "[font_size=22][b][color=#%s]%s[/color][/b][/font_size]\n%s" % [
		UITheme.ERROR.to_html(false) if not wise_refusal else UITheme.SKY.to_html(false),
		"Pedido recusado" if refused else "Venda perdida",
		text,
	]
	if not wise_refusal:
		body += "\n\n" + _solution_text()
	var effects := get_effects()
	if effects and not refused:
		effects.flash_panel(_panel, Color(0.9, 0.2, 0.2, 0.22))
	_show_result(body)
	_last_result = {
		"success": false,
		"refused": refused,
		"wise_refusal": wise_refusal,
		"customer": customer["name"],
		"topic": order["topic_name"],
		"revenue": 0.0,
		"cost": 0.0,
		"profit": 0.0,
		"xp": 0,
		"score": 0,
	}
	if log_it:
		GameState.record_attempt({
			"cliente": customer["name"],
			"perfil": customer["trait"],
			"topico": order["topic_name"],
			"pergunta": "%s %s" % [order["request"], order["question"]],
			"resposta_aluno": "(recusou)" if refused else "(tempo esgotado)",
			"resposta_correta": GameData.money(order["answer"]),
			"calculo_ok": false,
			"pedido_ok": false,
			"preco_ok": false,
			"venda_aceita": false,
			"usou_dica": _used_hint,
			"tempo_segundos": int((Time.get_ticks_msec() - _opened_at) / 1000.0),
		})
	resolved.emit(_last_result)


func _solution_text() -> String:
	var text := "[b]Resolução passo a passo[/b]"
	text += "\nPedido: %d × %s%s" % [order["qty"], order["product"], (" com " + str(order["discount"]) + "% de desconto") if int(order["discount"]) > 0 else ", sem desconto"]
	for step in order["solution"]:
		text += "\n• " + str(step)
	text += "\n[b]Resposta: %s[/b]" % GameData.money(order["answer"])
	return text


func _show_result(text: String) -> void:
	_form.visible = false
	_timer_bar.visible = false
	_result_box.visible = true
	_result_text.text = text
	_continue_button.grab_focus()


func _on_continue_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 0.0, 0.18)
	await tween.finished
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and _done and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_on_continue_pressed()
