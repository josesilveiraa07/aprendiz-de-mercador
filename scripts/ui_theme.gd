extends RefCounted
class_name UITheme
## Tema visual da interface: pergaminho + madeira + brasa, coerente com a
## direção de arte (paleta quente de mercado mediterrâneo / oficina medieval).
## É aplicado na raiz da árvore pelo GameState, então vale para todas as cenas.

const PARCHMENT := Color("f3e2c0")
const PARCHMENT_LIGHT := Color("fff4dc")
const PARCHMENT_DARK := Color("e2c99a")
const WOOD := Color("4a2c1d")
const WOOD_DARK := Color("2e1b12")
const WOOD_LIGHT := Color("6b3f22")
const INK := Color("3b2416")
const INK_SOFT := Color("6e5340")
const CREAM := Color("fbeed3")
const EMBER := Color("d9622b")
const EMBER_LIGHT := Color("ec7e45")
const EMBER_DARK := Color("a8461b")
const GOLD := Color("e0a526")
const SUCCESS := Color("4f8a3a")
const ERROR := Color("b83a2e")
const SKY := Color("3e6d8e")

## Textos e números: Atkinson Hyperlegible (5/S, 1/l e 0/O bem distintos —
## essencial num jogo de contas). Títulos: Pixelify Sans, pela identidade pixel art.
const FONT_REGULAR := "res://assets/fonts/AtkinsonHyperlegible-Regular.woff2"
const FONT_BOLD := "res://assets/fonts/AtkinsonHyperlegible-Bold.woff2"
const FONT_PIXEL := "res://assets/fonts/PixelifySans-Bold.woff2"


const FONT_SYMBOLS := "res://assets/fonts/SymbolsFallback.ttf"


static func pixel_font() -> Font:
	return _load_font(FONT_PIXEL)


static func font(bold: bool = false) -> Font:
	return _load_font(FONT_BOLD if bold else FONT_REGULAR)


static func _load_font(path: String) -> Font:
	if not ResourceLoader.exists(path):
		return ThemeDB.fallback_font
	var f: Font = load(path)
	# A fonte pixelada não tem ✔ ✘ ▸ ★: usa um subconjunto da DejaVu como reserva.
	if f.fallbacks.is_empty() and ResourceLoader.exists(FONT_SYMBOLS):
		f.fallbacks = [load(FONT_SYMBOLS)]
		# Desliga ligaduras: o "fi" da Pixelify aparecia como um glifo quebrado.
		if f is FontFile:
			(f as FontFile).opentype_feature_overrides = {
				TextServerManager.get_primary_interface().name_to_tag("liga"): 0,
				TextServerManager.get_primary_interface().name_to_tag("clig"): 0,
			}
	return f


static func box(bg: Color, border: Color = Color.TRANSPARENT, border_w: int = 0, radius: int = 6, pad: int = 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad * 0.6
	sb.content_margin_bottom = pad * 0.6
	sb.anti_aliasing = false
	return sb


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = font(false)
	t.default_font_size = 18

	# Textos
	t.set_color("font_color", "Label", INK)
	t.set_color("default_color", "RichTextLabel", INK)
	t.set_font("bold_font", "RichTextLabel", font(true))
	t.set_font("normal_font", "RichTextLabel", font(false))
	t.set_font_size("normal_font_size", "RichTextLabel", 18)
	t.set_font_size("bold_font_size", "RichTextLabel", 18)

	# Painéis de pergaminho (padrão)
	var parchment := box(PARCHMENT, WOOD_LIGHT, 3, 8, 14)
	parchment.shadow_color = Color(0, 0, 0, 0.35)
	parchment.shadow_size = 6
	parchment.shadow_offset = Vector2(0, 3)
	t.set_stylebox("panel", "PanelContainer", parchment)
	t.set_stylebox("panel", "Panel", parchment)

	# Variação: barra de madeira (HUD, cabeçalhos)
	t.set_type_variation("WoodPanel", "PanelContainer")
	var wood := box(WOOD, WOOD_DARK, 3, 8, 12)
	wood.shadow_color = Color(0, 0, 0, 0.4)
	wood.shadow_size = 4
	t.set_stylebox("panel", "WoodPanel", wood)

	# Variação: cartão interno (blocos dentro do pergaminho)
	t.set_type_variation("CardPanel", "PanelContainer")
	t.set_stylebox("panel", "CardPanel", box(PARCHMENT_LIGHT, PARCHMENT_DARK, 2, 6, 10))

	# Variação: rótulos claros (sobre madeira)
	t.set_type_variation("LightLabel", "Label")
	t.set_color("font_color", "LightLabel", CREAM)
	t.set_type_variation("TitleLabel", "Label")
	t.set_font("font", "TitleLabel", pixel_font())
	t.set_font_size("font_size", "TitleLabel", 26)
	t.set_color("font_color", "TitleLabel", WOOD)
	t.set_type_variation("NameLabel", "Label")
	t.set_font("font", "NameLabel", font(true))
	t.set_font_size("font_size", "NameLabel", 22)
	t.set_color("font_color", "NameLabel", WOOD)
	t.set_type_variation("SmallLabel", "Label")
	t.set_font_size("font_size", "SmallLabel", 15)
	t.set_color("font_color", "SmallLabel", INK_SOFT)

	# Botões principais (brasa)
	t.set_stylebox("normal", "Button", box(EMBER, EMBER_DARK, 2, 6, 14))
	t.set_stylebox("hover", "Button", box(EMBER_LIGHT, EMBER_DARK, 2, 6, 14))
	t.set_stylebox("pressed", "Button", box(EMBER_DARK, WOOD_DARK, 2, 6, 14))
	t.set_stylebox("disabled", "Button", box(Color("b9a58a"), Color("9c8a72"), 2, 6, 14))
	t.set_stylebox("focus", "Button", box(Color.TRANSPARENT, GOLD, 2, 6, 14))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(state, "Button", CREAM)
	t.set_color("font_disabled_color", "Button", Color("f0e6d2"))
	t.set_font("font", "Button", font(true))

	# Botões secundários (madeira)
	t.set_type_variation("SecondaryButton", "Button")
	t.set_stylebox("normal", "SecondaryButton", box(WOOD_LIGHT, WOOD_DARK, 2, 6, 12))
	t.set_stylebox("hover", "SecondaryButton", box(Color("80502d"), WOOD_DARK, 2, 6, 12))
	t.set_stylebox("pressed", "SecondaryButton", box(WOOD, WOOD_DARK, 2, 6, 12))

	# Botão de dica (dourado)
	t.set_type_variation("HintButton", "Button")
	t.set_stylebox("normal", "HintButton", box(GOLD, Color("9c6f10"), 2, 6, 12))
	t.set_stylebox("hover", "HintButton", box(Color("ecb84a"), Color("9c6f10"), 2, 6, 12))
	t.set_stylebox("pressed", "HintButton", box(Color("b8861a"), Color("7a560c"), 2, 6, 12))
	t.set_color("font_color", "HintButton", WOOD_DARK)
	t.set_color("font_hover_color", "HintButton", WOOD_DARK)
	t.set_color("font_pressed_color", "HintButton", WOOD_DARK)

	# Campos de texto / SpinBox
	t.set_stylebox("normal", "LineEdit", box(PARCHMENT_LIGHT, WOOD_LIGHT, 2, 4, 10))
	t.set_stylebox("focus", "LineEdit", box(Color.TRANSPARENT, EMBER, 3, 4, 10))
	t.set_stylebox("read_only", "LineEdit", box(PARCHMENT_DARK, WOOD_LIGHT, 2, 4, 10))
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_placeholder_color", "LineEdit", Color(INK_SOFT, 0.6))
	t.set_color("caret_color", "LineEdit", EMBER_DARK)
	t.set_color("selection_color", "LineEdit", Color(EMBER, 0.35))
	t.set_font_size("font_size", "LineEdit", 20)

	# Setas do SpinBox visíveis sobre o pergaminho
	for state in ["up_icon_modulate", "up_hover_icon_modulate", "up_pressed_icon_modulate",
			"down_icon_modulate", "down_hover_icon_modulate", "down_pressed_icon_modulate"]:
		t.set_color(state, "SpinBox", WOOD_LIGHT)

	# OptionButton e menus
	t.set_stylebox("normal", "OptionButton", box(PARCHMENT_LIGHT, WOOD_LIGHT, 2, 4, 10))
	t.set_stylebox("hover", "OptionButton", box(Color("fffaf0"), EMBER, 2, 4, 10))
	t.set_stylebox("pressed", "OptionButton", box(PARCHMENT_DARK, WOOD_LIGHT, 2, 4, 10))
	t.set_stylebox("focus", "OptionButton", box(Color.TRANSPARENT, EMBER, 2, 4, 10))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(state, "OptionButton", INK)
	t.set_stylebox("panel", "PopupMenu", box(PARCHMENT_LIGHT, WOOD_LIGHT, 2, 4, 6))
	t.set_stylebox("hover", "PopupMenu", box(Color(EMBER, 0.85), Color.TRANSPARENT, 0, 3, 6))
	t.set_color("font_color", "PopupMenu", INK)
	t.set_color("font_hover_color", "PopupMenu", CREAM)

	# Barras de progresso
	t.set_stylebox("background", "ProgressBar", box(WOOD_DARK, WOOD_DARK, 2, 4, 0))
	t.set_stylebox("fill", "ProgressBar", box(GOLD, Color.TRANSPARENT, 0, 3, 0))
	t.set_color("font_color", "ProgressBar", CREAM)
	t.set_font_size("font_size", "ProgressBar", 13)

	t.set_stylebox("separator", "HSeparator", box(PARCHMENT_DARK, Color.TRANSPARENT, 0, 0, 0))
	t.set_constant("separation", "HSeparator", 6)

	t.set_stylebox("panel", "TooltipPanel", box(WOOD_DARK, GOLD, 1, 4, 8))
	t.set_color("font_color", "TooltipLabel", CREAM)
	return t


## Escala usada nos textos dentro do mundo (balões, dicas de porta).
## O texto é desenhado 4× maior e reduzido, para continuar nítido com o zoom
## da câmera (senão a fonte é rasterizada em 6 px e fica borrada).
const WORLD_TEXT_SCALE := 0.25


## Cria um rótulo para o mundo 2D. Tamanhos em "pixels do mundo".
static func world_label(font_px: float, width: float = 0.0, bubble: bool = false) -> Label:
	var k := 1.0 / WORLD_TEXT_SCALE
	var label := Label.new()
	label.scale = Vector2.ONE * WORLD_TEXT_SCALE
	label.z_as_relative = false
	label.z_index = 200
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font(true))
	label.add_theme_font_size_override("font_size", int(font_px * k))
	if width > 0.0:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(width * k, 0)
	if bubble:
		label.add_theme_color_override("font_color", INK)
		var sb := box(PARCHMENT_LIGHT, WOOD_LIGHT, int(k), int(3 * k), int(4 * k))
		sb.content_margin_top = 2 * k
		sb.content_margin_bottom = 2 * k
		label.add_theme_stylebox_override("normal", sb)
	else:
		label.add_theme_color_override("font_color", CREAM)
		label.add_theme_color_override("font_outline_color", WOOD_DARK)
		label.add_theme_constant_override("outline_size", int(3 * k))
	return label


## Posiciona um rótulo do mundo centralizado acima de um ponto.
static func place_world_label(label: Label, anchor: Vector2) -> void:
	label.reset_size()
	var visual := label.size * WORLD_TEXT_SCALE
	label.position = anchor - Vector2(visual.x * 0.5, visual.y)
