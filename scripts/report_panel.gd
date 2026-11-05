extends Control
class_name ReportPanel
## Relatório para o professor (apoio ao "Teste com o público real" da N2).
## Mostra o desempenho da sessão por conteúdo e exporta um CSV que abre
## direto no Excel/Google Sheets (separador ";", padrão brasileiro).

signal closed

var _name_input: LineEdit
var _stats: RichTextLabel
var _status: RichTextLabel


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.04, 0.02, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 0)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Relatório da sessão (professor)"
	title.theme_type_variation = "TitleLabel"
	vbox.add_child(title)

	var info := Label.new()
	info.theme_type_variation = "SmallLabel"
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.text = "Cada resposta dada no balcão fica registrada nesta sessão. Exporte ao final da aula para comparar turmas e identificar os conteúdos com mais erros."
	vbox.add_child(info)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	vbox.add_child(name_row)
	var name_label := Label.new()
	name_label.text = "Aluno / grupo:"
	name_row.add_child(name_label)
	_name_input = LineEdit.new()
	_name_input.placeholder_text = "ex.: 7º B — dupla 3"
	_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_input.text_changed.connect(func(t: String) -> void: GameState.player_name = t)
	name_row.add_child(_name_input)

	var card := PanelContainer.new()
	card.theme_type_variation = "CardPanel"
	vbox.add_child(card)
	_stats = RichTextLabel.new()
	_stats.bbcode_enabled = true
	_stats.fit_content = true
	_stats.scroll_active = false
	_stats.add_theme_constant_override("table_h_separation", 22)
	card.add_child(_stats)

	_status = RichTextLabel.new()
	_status.bbcode_enabled = true
	_status.fit_content = true
	_status.scroll_active = false
	_status.add_theme_font_size_override("normal_font_size", 15)
	vbox.add_child(_status)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	vbox.add_child(buttons)
	var back := Button.new()
	back.text = "Voltar"
	back.theme_type_variation = "SecondaryButton"
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.custom_minimum_size = Vector2(0, 44)
	back.pressed.connect(func() -> void:
		AudioManager.play_sfx("button_click")
		visible = false
		closed.emit()
	)
	buttons.add_child(back)
	var export := Button.new()
	export.text = "Exportar planilha (CSV)"
	export.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	export.custom_minimum_size = Vector2(0, 44)
	export.pressed.connect(_on_export)
	buttons.add_child(export)


func show_report() -> void:
	_name_input.text = GameState.player_name
	_status.text = ""
	var stats := GameState.topic_stats()
	if stats.is_empty():
		_stats.text = "Nenhuma venda registrada nesta sessão ainda. Jogue alguns dias e volte aqui."
	else:
		var text := "[table=4][cell][b]Conteúdo[/b]   [/cell][cell][b]Tentativas[/b]   [/cell][cell][b]Acertos de cálculo[/b]   [/cell][cell][b]Pediu dica[/b][/cell]"
		var total := 0
		var right := 0
		for topic in stats:
			var s: Dictionary = stats[topic]
			total += int(s["total"])
			right += int(s["acertos"])
			var pct := 100.0 * float(s["acertos"]) / maxf(1.0, float(s["total"]))
			var color := (UITheme.SUCCESS if pct >= 70.0 else (Color("9c6f10") if pct >= 40.0 else UITheme.ERROR)).to_html(false)
			text += "[cell]%s[/cell][cell]%d[/cell][cell][color=#%s]%d (%d%%)[/color][/cell][cell]%d[/cell]" % [topic, s["total"], color, s["acertos"], roundi(pct), s["dicas"]]
		text += "[/table]\n\nTotal: [b]%d[/b] tentativas · [b]%d%%[/b] de acerto no cálculo · sessão iniciada em %s" % [
			total, roundi(100.0 * right / maxf(1.0, total)), GameState.session_started.replace("T", " ")
		]
		_stats.text = text
	visible = true


func _on_export() -> void:
	AudioManager.play_sfx("button_click")
	if GameState.attempts.is_empty():
		_status.text = "[color=#%s]Ainda não há tentativas para exportar.[/color]" % UITheme.ERROR.to_html(false)
		return
	var path := GameState.export_report_csv()
	if path.is_empty():
		_status.text = "[color=#%s]Não foi possível salvar o arquivo.[/color]" % UITheme.ERROR.to_html(false)
		return
	_status.text = "Planilha salva em:\n[b]%s[/b]" % path
	OS.shell_open(path.get_base_dir())
