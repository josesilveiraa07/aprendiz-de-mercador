extends RefCounted
class_name GameData
## Dados de design do jogo (bairros, produtos, clientes e narrativa).
## Tudo que é "conteúdo" fica aqui para a equipe ajustar sem mexer na lógica.

# ---------------------------------------------------------------- Progressão
const LEVEL_NAMES := {1: "Barraca Simples", 2: "Loja Pequena", 3: "Mercado Geral"}
## XP total necessário para alcançar cada nível.
const LEVEL_XP := {1: 0, 2: 5, 3: 12}
const MAX_LEVEL := 3
## Clientes atendidos por dia, por nível da loja.
const CUSTOMERS_PER_DAY := {1: 3, 2: 4, 3: 5}
const START_MONEY := 60.0
const START_STOCK := {"Maçã": 4, "Pão": 4}
## Ajuda da vó quando o caixa fica negativo no fim do dia.
const GRANDMA_LOAN := 30.0

# ------------------------------------------------------------------- Bairros
## Cada bairro tem produtos, preço de compra (fornecedor) e preço de venda base.
## "tint" pinta a cena para diferenciar os bairros visualmente.
const DISTRICTS := {
	"porto": {
		"name": "Bairro do Porto",
		"unlock_level": 1,
		"tint": Color(1.0, 0.97, 0.92),
		"description": "Pescadores e marinheiros. Compras pequenas, troco e descontos simples.",
		"products": {
			"Maçã": {"buy": 3.0, "base": 5.0},
			"Pão": {"buy": 2.0, "base": 4.0},
			"Queijo": {"buy": 6.0, "base": 10.0},
			"Especiaria": {"buy": 8.0, "base": 14.0},
		},
		"customers": ["ivone", "bartolomeu", "lia"],
	},
	"vidreiros": {
		"name": "Rua dos Vidreiros",
		"unlock_level": 2,
		"tint": Color(0.9, 0.95, 1.05),
		"description": "Artesãos do vidro. Descontos em porcentagem e frações.",
		"products": {
			"Copo de vidro": {"buy": 4.0, "base": 8.0},
			"Garrafa": {"buy": 6.0, "base": 12.0},
			"Vaso": {"buy": 12.0, "base": 20.0},
			"Contas de vidro": {"buy": 1.0, "base": 2.5},
		},
		"customers": ["ivone", "bartolomeu", "lia", "tome", "rui"],
	},
	"coroa": {
		"name": "Praça da Coroa",
		"unlock_level": 3,
		"tint": Color(1.05, 0.95, 0.85),
		"description": "Nobres e capitães. Pedidos grandes, risco de prejuízo.",
		"products": {
			"Tecido fino": {"buy": 15.0, "base": 24.0},
			"Perfume": {"buy": 18.0, "base": 30.0},
			"Especiaria rara": {"buy": 9.5, "base": 16.0},
			"Vitral": {"buy": 40.0, "base": 60.0},
		},
		"customers": ["bartolomeu", "lia", "tome", "rui", "odete"],
	},
}
const DISTRICT_ORDER := ["porto", "vidreiros", "coroa"]

# ------------------------------------------------------------------ Clientes
## Personalidades distintas (entrega N2):
##   min_score   -> quantos critérios (Cálculo, Pedido, Preço) precisam estar certos
##   retries     -> quantas novas tentativas o cliente aceita depois de um erro
##   time_limit  -> segundos de paciência (0 = sem pressa)
##   topics      -> desafios matemáticos que esse cliente costuma trazer
##   colors      -> troca de paleta do sprite (matiz, saturação, brilho) p/ cabelo/capa/camisa
const CUSTOMERS := {
	"ivone": {
		"name": "Dona Ivone",
		"trait": "Paciente",
		"trait_desc": "Aceita 2 de 3 critérios e dá uma segunda chance.",
		"min_level": 1,
		"min_score": 2,
		"retries": 1,
		"time_limit": 0,
		"xp_bonus": 0,
		"topics": ["total", "troco"],
		"greetings": [
			"Bom dia, meu jovem! Sem pressa, viu?",
			"Sua avó sempre me atendeu tão bem... vamos ver você!",
		],
		"happy": "Que capricho! Volto amanhã.",
		"sad": "Hmm, acho que a conta não fechou...",
		"colors": {"hair": Vector3(0.0, 0.05, 1.35), "cloak": Vector3(0.33, 0.45, 1.1), "shirt": Vector3(0.88, 0.5, 1.0)},
	},
	"bartolomeu": {
		"name": "Seu Bartolomeu",
		"trait": "Pechincheiro",
		"trait_desc": "Sempre pede desconto. Confira a porcentagem!",
		"min_level": 1,
		"min_score": 2,
		"retries": 0,
		"time_limit": 0,
		"xp_bonus": 0,
		"topics": ["desconto", "desconto", "lucro"],
		"greetings": [
			"Esse preço tá salgado! Faz um desconto pro velho Bartô?",
			"Eu só compro com desconto, garoto. Regra da casa!",
		],
		"happy": "Negócio fechado! Você é dos bons.",
		"sad": "Assim não dá! Vou comprar no vizinho.",
		"colors": {"hair": Vector3(0.07, 0.55, 0.55), "cloak": Vector3(0.0, 0.7, 0.95), "shirt": Vector3(0.12, 0.6, 0.9)},
	},
	"lia": {
		"name": "Lia, a mensageira",
		"trait": "Apressada",
		"trait_desc": "Tem pouco tempo e paga com moedas grandes: calcule o troco.",
		"min_level": 1,
		"min_score": 2,
		"retries": 0,
		"time_limit": 75,
		"xp_bonus": 0,
		"topics": ["troco", "troco", "total"],
		"greetings": [
			"Rápido, rápido! Tenho entregas no porto!",
			"Oi! Só tenho um minutinho, tá?",
		],
		"happy": "Valeu! Já tô atrasada!",
		"sad": "Demorou demais... fui!",
		"colors": {"hair": Vector3(0.13, 0.75, 1.25), "cloak": Vector3(0.78, 0.55, 1.0), "shirt": Vector3(0.55, 0.45, 1.1)},
	},
	"tome": {
		"name": "Tomé, o aprendiz",
		"trait": "Curioso",
		"trait_desc": "Fala em frações: metade, um quarto, um quinto...",
		"min_level": 2,
		"min_score": 2,
		"retries": 1,
		"time_limit": 0,
		"xp_bonus": 0,
		"topics": ["fracao", "fracao", "desconto"],
		"greetings": [
			"Meu mestre disse que hoje tem preço em fração. É verdade?",
			"Você sabia que 1/4 é a mesma coisa que 25%?",
		],
		"happy": "Aprendi mais uma! Obrigado!",
		"sad": "Acho que a fração ficou errada...",
		"colors": {"hair": Vector3(0.09, 0.35, 0.35), "cloak": Vector3(0.45, 0.5, 0.95), "shirt": Vector3(0.0, 0.0, 1.3)},
	},
	"rui": {
		"name": "Capitão Rui",
		"trait": "Exigente",
		"trait_desc": "Só aceita a venda com os 3 critérios certos. Dá XP extra.",
		"min_level": 2,
		"min_score": 3,
		"retries": 0,
		"time_limit": 0,
		"xp_bonus": 1,
		"topics": ["desconto", "lucro", "troco"],
		"greetings": [
			"No meu navio, conta errada é motivo de prancha. Capricha!",
			"Quero tudo certinho, rapaz. Sem arredondar!",
		],
		"happy": "Contas exatas. Você tem futuro no comércio.",
		"sad": "Errado. E eu não dou segunda chance.",
		"colors": {"hair": Vector3(0.0, 0.0, 0.3), "cloak": Vector3(0.62, 0.65, 0.7), "shirt": Vector3(0.0, 0.0, 1.4)},
	},
	"odete": {
		"name": "Madame Odete",
		"trait": "Nobre",
		"trait_desc": "Compra muito e quer saber o seu lucro (ou prejuízo).",
		"min_level": 3,
		"min_score": 2,
		"retries": 0,
		"time_limit": 0,
		"xp_bonus": 1,
		"topics": ["lucro", "desconto", "fracao"],
		"greetings": [
			"Querido, quero o melhor. E diga-me: está ganhando ou perdendo com isso?",
			"Compro em quantidade. Mas um desconto generoso é de bom tom.",
		],
		"happy": "Encantador. Recomendarei sua loja na corte.",
		"sad": "Que deselegante. Até nunca mais.",
		"colors": {"hair": Vector3(0.95, 0.45, 1.0), "cloak": Vector3(0.83, 0.6, 0.9), "shirt": Vector3(0.14, 0.75, 1.1)},
	},
}

# ----------------------------------------------------------------- Narrativa
## Diálogos da avó de Marco. Cada fala: [quem, texto].
const GRANDMA_NAME := "Vó Celeste"
const STORY := {
	"intro": [
		["Vó Celeste", "Marco, meu neto... chegou o dia. Esta barraca no Bairro do Porto agora é sua."],
		["Marco", "Minha, vó? Mas eu nunca vendi nada sozinho!"],
		["Vó Celeste", "Vendeu sim: lembra de quando contávamos moedas juntos na mesa da cozinha? É a mesma coisa."],
		["Vó Celeste", "De manhã você compra a mercadoria do fornecedor. Durante o dia, atende os clientes no balcão."],
		["Vó Celeste", "Cada cliente tem seu jeito. Uns pedem desconto, outros têm pressa, outros só aceitam conta exata."],
		["Vó Celeste", "Na hora da venda, três coisas importam: o PEDIDO certo, o PREÇO certo e o CÁLCULO certo."],
		["Vó Celeste", "Se travar numa conta, clique em \"Dica da vó\". Eu estarei sempre por perto."],
		["Marco", "Tá bom, vó. Vou fazer a senhora sentir orgulho!"],
	],
	"level_2": [
		["Vó Celeste", "Recebi a notícia: a barraca virou uma Loja Pequena! Estou tão orgulhosa."],
		["Vó Celeste", "Agora você pode vender na Rua dos Vidreiros. Lá o povo fala em porcentagem e em frações."],
		["Vó Celeste", "Um segredo: 10% é dividir por 10. 25% é a quarta parte. 50% é a metade."],
		["Marco", "Então 1/4 de desconto é o mesmo que 25%? Anotado!"],
	],
	"level_3": [
		["Vó Celeste", "Marco... um Mercado Geral! Seu avô nunca chegou tão longe."],
		["Vó Celeste", "A Praça da Coroa está aberta para você. Mas cuidado: desconto grande demais vira PREJUÍZO."],
		["Vó Celeste", "Se você vende por menos do que pagou, o lucro fica negativo. Número negativo também é resposta!"],
		["Marco", "Vou ficar de olho no lucro, vó. Prometo."],
	],
	"finale": [
		["Vó Celeste", "Dez dias como Mercado Geral, e as contas sempre em ordem."],
		["Vó Celeste", "Você não precisa mais de mim no balcão, Marco. Mas eu vou continuar passando aqui para um café."],
		["Marco", "A loja vai ser sempre sua também, vó."],
	],
	"loan": [
		["Vó Celeste", "Marco, o caixa ficou negativo. Saldo abaixo de zero quer dizer que você está devendo."],
		["Vó Celeste", "Vou te emprestar 30 moedas. Compre só o que conseguir vender, combinado?"],
	],
}
## Dias como Mercado Geral até o epílogo da história.
const FINALE_AFTER_DAYS_AT_MAX := 10


static func district_products(district_id: String) -> Dictionary:
	return DISTRICTS[district_id]["products"]


static func find_product(product_name: String) -> Dictionary:
	for district_id in DISTRICT_ORDER:
		var products: Dictionary = DISTRICTS[district_id]["products"]
		if products.has(product_name):
			return products[product_name]
	return {}


static func level_name(level: int) -> String:
	return LEVEL_NAMES.get(level, LEVEL_NAMES[MAX_LEVEL])


static func unlocked_districts(level: int) -> Array:
	var result := []
	for district_id in DISTRICT_ORDER:
		if int(DISTRICTS[district_id]["unlock_level"]) <= level:
			result.append(district_id)
	return result


## Formata dinheiro no padrão brasileiro: 12,50
static func money(value: float, decimals: int = 2) -> String:
	var negative := value < -0.0049
	var text := String.num(absf(value), decimals)
	if decimals > 0 and not text.contains("."):
		text += "." + "0".repeat(decimals)
	var parts := text.split(".")
	if parts.size() == 2 and parts[1].length() < decimals:
		parts[1] = parts[1] + "0".repeat(decimals - parts[1].length())
	text = parts[0] if parts.size() == 1 else parts[0] + "," + parts[1]
	return ("-" if negative else "") + text


## Formata número "limpo": 12 (inteiro) ou 12,50 (com centavos).
static func num(value: float) -> String:
	if absf(value - roundf(value)) < 0.001:
		return str(int(roundf(value)))
	return money(value, 2)


## Lê a resposta digitada pelo aluno aceitando vírgula, ponto, espaços e "R$".
## Retorna NAN quando o texto não é um número.
static func parse_answer(text: String) -> float:
	var clean := text.strip_edges().replace(" ", "").replace("R$", "").replace("$", "")
	clean = clean.replace("−", "-")
	if clean.count(",") == 1 and clean.count(".") >= 1:
		clean = clean.replace(".", "")  # 1.234,50 -> 1234,50
	clean = clean.replace(",", ".")
	if clean.is_empty() or not clean.is_valid_float():
		return NAN
	return clean.to_float()
