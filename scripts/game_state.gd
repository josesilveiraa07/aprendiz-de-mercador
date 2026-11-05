extends Node
## Estado global da partida (autoload "GameState").
## Antes o caixa, o XP e o dia viviam dentro do painel de negociação e se
## perdiam ao trocar de cena. Agora ficam aqui, com save automático.

signal money_changed(previous: float, current: float)
signal xp_changed(xp: int, level: int)
signal level_up(new_level: int)

const SAVE_PATH := "user://save.json"
const REPORT_DIR := "user://relatorios"

var day := 1
var money := GameData.START_MONEY
var xp := 0
var level := 1
var district := "porto"
var stock: Dictionary = {}
var days_at_max_level := 0
var story_seen: Dictionary = {}
var muted := false

## Resultados do dia corrente (para o resumo do entardecer).
var today: Dictionary = {}
## Registro de todas as tentativas da sessão (para o relatório do professor).
var attempts: Array = []
var session_started := ""
var player_name := ""
## Tema da interface. Também é aplicado manualmente nos nós dentro de
## CanvasLayer, que não herdam o tema da janela raiz.
var ui_theme: Theme


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	session_started = Time.get_datetime_string_from_system()
	ui_theme = UITheme.build()
	get_tree().root.theme = ui_theme
	reset()


func reset() -> void:
	day = 1
	money = GameData.START_MONEY
	xp = 0
	level = 1
	district = "porto"
	stock = GameData.START_STOCK.duplicate()
	days_at_max_level = 0
	story_seen = {}
	_reset_today()


func _reset_today() -> void:
	today = {
		"customers": [],
		"revenue": 0.0,
		"cost_of_goods": 0.0,
		"purchases": 0.0,
		"xp_gained": 0,
		"money_start": money,
	}


# ------------------------------------------------------------------ Dinheiro
func add_money(amount: float) -> void:
	var previous := money
	money = snappedf(money + amount, 0.01)
	money_changed.emit(previous, money)


func buy_stock(product: String, qty: int, unit_cost: float) -> bool:
	var total := unit_cost * qty
	if qty <= 0 or total > money + 0.001:
		return false
	add_money(-total)
	stock[product] = int(stock.get(product, 0)) + qty
	today["purchases"] = float(today["purchases"]) + total
	return true


func stock_of(product: String) -> int:
	return int(stock.get(product, 0))


func remove_stock(product: String, qty: int) -> void:
	stock[product] = maxi(0, stock_of(product) - qty)


# ------------------------------------------------------------------------ XP
func xp_for_next_level() -> int:
	if level >= GameData.MAX_LEVEL:
		return -1
	return int(GameData.LEVEL_XP[level + 1])


func add_xp(amount: int) -> bool:
	if amount <= 0:
		return false
	xp += amount
	today["xp_gained"] = int(today["xp_gained"]) + amount
	var leveled := false
	while level < GameData.MAX_LEVEL and xp >= int(GameData.LEVEL_XP[level + 1]):
		level += 1
		leveled = true
		level_up.emit(level)
	xp_changed.emit(xp, level)
	return leveled


# ----------------------------------------------------------------------- Dia
func customers_per_day() -> int:
	return int(GameData.CUSTOMERS_PER_DAY.get(level, 3))


func start_day() -> void:
	_reset_today()


func record_customer(result: Dictionary) -> void:
	today["customers"].append(result)
	if result.get("success", false):
		today["revenue"] = float(today["revenue"]) + float(result.get("revenue", 0.0))
		today["cost_of_goods"] = float(today["cost_of_goods"]) + float(result.get("cost", 0.0))


func record_attempt(entry: Dictionary) -> void:
	entry["dia"] = day
	entry["bairro"] = GameData.DISTRICTS[district]["name"]
	entry["horario"] = Time.get_time_string_from_system()
	attempts.append(entry)


## Fecha o dia. Retorna true se a vó precisou emprestar dinheiro.
func end_day() -> bool:
	var needed_loan := money < 0.0
	if needed_loan:
		add_money(GameData.GRANDMA_LOAN)
	if level >= GameData.MAX_LEVEL:
		days_at_max_level += 1
	day += 1
	save_game()
	return needed_loan


# ------------------------------------------------------------- Persistência
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var data := {
		"day": day,
		"money": money,
		"xp": xp,
		"level": level,
		"district": district,
		"stock": stock,
		"days_at_max_level": days_at_max_level,
		"story_seen": story_seen,
		"muted": muted,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))


func load_game() -> bool:
	if not has_save():
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed
	day = int(data.get("day", 1))
	money = float(data.get("money", GameData.START_MONEY))
	xp = int(data.get("xp", 0))
	level = clampi(int(data.get("level", 1)), 1, GameData.MAX_LEVEL)
	district = str(data.get("district", "porto"))
	if not GameData.DISTRICTS.has(district):
		district = "porto"
	stock = {}
	var saved_stock: Dictionary = data.get("stock", {})
	for key in saved_stock:
		stock[key] = int(saved_stock[key])
	days_at_max_level = int(data.get("days_at_max_level", 0))
	story_seen = data.get("story_seen", {})
	set_muted(bool(data.get("muted", false)))
	_reset_today()
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


# ---------------------------------------------------------------------- Som
func set_muted(value: bool) -> void:
	muted = value
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), muted)


func toggle_mute() -> void:
	set_muted(not muted)
	save_game()


# ------------------------------------------------- Relatório para professor
## Estatísticas por tópico: {topico: {"total": n, "acertos": n}}
func topic_stats() -> Dictionary:
	var stats := {}
	for entry in attempts:
		var topic: String = entry.get("topico", "?")
		if not stats.has(topic):
			stats[topic] = {"total": 0, "acertos": 0, "dicas": 0}
		stats[topic]["total"] += 1
		if entry.get("calculo_ok", false):
			stats[topic]["acertos"] += 1
		if entry.get("usou_dica", false):
			stats[topic]["dicas"] += 1
	return stats


## Exporta todas as tentativas da sessão em CSV (abre no Excel/Sheets).
## Retorna o caminho absoluto do arquivo, ou "" se falhar.
func export_report_csv() -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path := "%s/sessao_%s.csv" % [REPORT_DIR, stamp]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ""
	var columns := [
		"aluno", "dia", "horario", "bairro", "cliente", "perfil", "topico", "pergunta",
		"resposta_aluno", "resposta_correta", "calculo_ok", "pedido_ok", "preco_ok",
		"venda_aceita", "usou_dica", "tempo_segundos",
	]
	file.store_line(";".join(columns))
	for entry in attempts:
		var row: PackedStringArray = []
		for column in columns:
			var value: Variant = player_name if column == "aluno" else entry.get(column, "")
			if typeof(value) == TYPE_BOOL:
				value = "sim" if value else "não"
			var text := str(value).replace(";", ",").replace("\n", " ")
			row.append(text)
		file.store_line(";".join(row))
	file.close()
	return ProjectSettings.globalize_path(path)
