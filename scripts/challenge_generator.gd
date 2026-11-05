extends RefCounted
class_name ChallengeGenerator
## Gera o pedido do cliente e o desafio matemático correspondente.
## Cobre os quatro conteúdos do GDD: decimais, porcentagens, frações e
## números negativos (lucro/prejuízo), além de multiplicação e troco.

const TOPIC_NAMES := {
	"total": "Multiplicação",
	"troco": "Troco (subtração)",
	"desconto": "Porcentagem",
	"fracao": "Frações",
	"lucro": "Lucro e prejuízo",
}

const FRACTIONS := [
	{"label": "a metade", "frac": "1/2", "pct": 50},
	{"label": "um quarto", "frac": "1/4", "pct": 25},
	{"label": "um quinto", "frac": "1/5", "pct": 20},
	{"label": "um décimo", "frac": "1/10", "pct": 10},
]

const DISCOUNTS_BY_LEVEL := {
	1: [10, 50],
	2: [10, 20, 25, 50],
	3: [5, 15, 20, 25, 30, 40, 50],
}

const QTY_BY_LEVEL := {1: Vector2i(1, 4), 2: Vector2i(2, 6), 3: Vector2i(3, 9)}
const COINS := [5, 10, 20, 50, 100, 200, 500]


static func generate(district_id: String, customer: Dictionary, level: int) -> Dictionary:
	var products: Dictionary = GameData.district_products(district_id)
	var product := _pick_product(products)
	var data: Dictionary = products[product]
	var base: float = data["base"]
	var buy: float = data["buy"]

	var qty_range: Vector2i = QTY_BY_LEVEL.get(level, Vector2i(1, 4))
	var qty := randi_range(qty_range.x, qty_range.y)
	if customer.get("trait", "") == "Nobre":
		qty += 2

	var topics: Array = customer.get("topics", ["total"]).duplicate()
	var topic: String = topics[randi() % topics.size()]
	if topic == "fracao" and level < 2:
		topic = "desconto"

	var discount := 0
	var discount_text := ""
	var fraction := {}
	match topic:
		"desconto":
			discount = _pick_discount(level, base, buy)
			discount_text = "%d%% de desconto" % discount
		"fracao":
			fraction = FRACTIONS[randi() % FRACTIONS.size()]
			if level < 3 and base * (1.0 - fraction["pct"] / 100.0) < buy:
				fraction = FRACTIONS[3]
			discount = int(fraction["pct"])
			if fraction["pct"] == 50:
				discount_text = "pela metade do preço (1/2 de desconto)"
			else:
				discount_text = "com %s de desconto (%s a menos no preço)" % [fraction["frac"], fraction["label"]]
		"lucro":
			if level >= 2 and randf() < 0.6:
				discount = _pick_discount(level, base, buy)
				discount_text = "%d%% de desconto" % discount
		"troco", "total":
			if level >= 2 and randf() < 0.4:
				discount = _pick_discount(level, base, buy)
				discount_text = "%d%% de desconto" % discount

	var unit_final := snappedf(base * (1.0 - discount / 100.0), 0.01)
	var total := snappedf(unit_final * qty, 0.01)
	var cost := snappedf(buy * qty, 0.01)

	var order := {
		"product": product,
		"qty": qty,
		"discount": discount,
		"discount_text": discount_text,
		"unit_base": base,
		"unit_buy": buy,
		"unit_final": unit_final,
		"total": total,
		"cost": cost,
		"topic": topic,
		"topic_name": TOPIC_NAMES.get(topic, topic),
		"paid": 0.0,
	}

	var steps: Array = []
	if discount > 0:
		var cut := snappedf(base * discount / 100.0, 0.01)
		steps.append("Desconto por unidade: %s%% de %s = %s × %d ÷ 100 = %s" % [discount, GameData.money(base), GameData.money(base), discount, GameData.money(cut)])
		steps.append("Preço com desconto: %s − %s = %s" % [GameData.money(base), GameData.money(cut), GameData.money(unit_final)])
	steps.append("Total: %s × %d = %s" % [GameData.money(unit_final), qty, GameData.money(total)])

	match topic:
		"troco":
			var paid := _coin_above(total)
			order["paid"] = paid
			order["question"] = "O cliente paga com uma moeda de %s. Quanto de TROCO você devolve?" % GameData.num(paid)
			order["answer"] = snappedf(paid - total, 0.01)
			steps.append("Troco: %s − %s = %s" % [GameData.money(paid), GameData.money(total), GameData.money(order["answer"])])
			order["hint"] = "Primeiro descubra o total (preço × quantidade). Depois tire esse total do valor que o cliente entregou."
		"lucro":
			order["question"] = "Você pagou %s por unidade ao fornecedor. Qual é o seu LUCRO nesta venda? (Se for prejuízo, use o sinal de menos.)" % GameData.money(buy)
			order["answer"] = snappedf(total - cost, 0.01)
			steps.append("Custo: %s × %d = %s" % [GameData.money(buy), qty, GameData.money(cost)])
			steps.append("Lucro: %s − %s = %s%s" % [GameData.money(total), GameData.money(cost), GameData.money(order["answer"]), "  (prejuízo!)" if order["answer"] < 0 else ""])
			order["hint"] = "Lucro = quanto você recebeu − quanto você pagou. Se você pagou mais do que recebeu, o resultado é negativo."
		"fracao":
			order["question"] = "Quanto o cliente vai pagar no TOTAL?"
			order["answer"] = total
			steps.insert(0, "Fração em porcentagem: %s = %d ÷ 100 = %d%%" % [fraction["frac"], fraction["pct"], fraction["pct"]])
			order["hint"] = "Transforme a fração em porcentagem: 1/2 = 50%, 1/4 = 25%, 1/5 = 20%, 1/10 = 10%. Coloque esse número no campo Desconto."
		"desconto":
			order["question"] = "Quanto o cliente vai pagar no TOTAL, já com o desconto?"
			order["answer"] = total
			order["hint"] = "%d%% de um valor = valor × %d ÷ 100. Tire o desconto do preço de UMA unidade e depois multiplique pela quantidade." % [discount, discount]
		_:
			order["question"] = "Quanto o cliente vai pagar no TOTAL?"
			order["answer"] = total
			order["hint"] = "Total = preço de uma unidade × quantidade. Se tiver desconto, aplique antes de multiplicar."

	order["solution"] = steps
	order["request"] = _request_text(order)
	return order


static func _pick_product(products: Dictionary) -> String:
	var names: Array = products.keys()
	var in_stock := names.filter(func(p: String) -> bool: return GameState.stock_of(p) > 0)
	if not in_stock.is_empty() and randf() < 0.75:
		return in_stock[randi() % in_stock.size()]
	return names[randi() % names.size()]


static func _pick_discount(level: int, base: float, buy: float) -> int:
	var options: Array = DISCOUNTS_BY_LEVEL.get(level, [10]).duplicate()
	if level < 3:
		# Até o nível 3 o desconto nunca gera prejuízo.
		options = options.filter(func(d: int) -> bool: return base * (1.0 - d / 100.0) >= buy)
		if options.is_empty():
			options = [10]
	return options[randi() % options.size()]


static func _coin_above(total: float) -> float:
	for coin in COINS:
		if coin > total + 0.001:
			# às vezes paga com a moeda seguinte, para variar a conta
			var index := COINS.find(coin)
			if randf() < 0.3 and index + 1 < COINS.size() and total > 3:
				return float(COINS[index + 1])
			return float(coin)
	return ceilf(total / 100.0) * 100.0 + 100.0


static func _request_text(order: Dictionary) -> String:
	var text := "Quero %d × %s" % [order["qty"], order["product"]]
	if not str(order["discount_text"]).is_empty():
		text += ", " + str(order["discount_text"])
	return text + "."
